//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation

public struct Sequential: AnimationProviderProtocol {
    private let animations: [AnimationProviderProtocol]
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[fullDuration], animation: self)
    }
    private let fullDuration: AnimationDuration?
    private let interator: Interactor
    
    public init(_ animations: [AnimationProviderProtocol]) {
        self.animations = animations
        self.fullDuration = Sequential.fullDuration(for: animations)
        self.interator = Interactor()
    }
    
    public init(_ animations: AnimationProviderProtocol...) {
        self = .init(animations)
    }
    
    public init(@AnimatorBuilder _ animations: () -> [AnimationProviderProtocol]) {
        self = .init(animations())
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        guard !animations.isEmpty else {
            completion(true)
            return
        }
        guard animations.count > 1 else {
            animations[0].start(with: options, completion)
            return
        }
        let array = getOptions(for: options)
        start(index: 0, options: array, reversed: options.autoreverseStep == .back, completion)
    }
    
    private func start(index: Int, options: [AnimationOptions], reversed: Bool, _ completion: @escaping (Bool) -> ()) {
        interator.prevIndex = nil
        guard index < animations.count else {
            completion(true)
            return
        }
        let i = reversed ? animations.count - index - 1 : index
        animations[i].start(with: options[i]) {
            guard $0 else {
                return completion(false)
            }
            self.start(index: index + 1, options: options, reversed: reversed, completion)
        }
    }
    
    public func canSet(state: AnimationState, for options: AnimationOptions) -> Bool {
        let state = options.isReversed == true ? state.reversed : state
        switch state {
        case .start, .end:
            return animations.reduce(while: { $0 }, true, { $0 && $1.canSet(state: state, for: .empty) })
        case .progress(let k):
            let array = getProgresses(animations.map({ $0.modificators }), duration: fullDuration?.absolute ?? 0, options: .empty)
            var result = true
            for i in 0..<array.count {
                if array[i].upperBound <= k || array[i].upperBound == 0 {
                    result = result && animations[i].canSet(state: .end, for: .empty)
                } else if array[i].lowerBound >= k {
                    result = result && animations[i].canSet(state: .start, for: .empty)
                } else {
                    result = result && animations[i].canSet(state: .progress((k - array[i].lowerBound) / (array[i].upperBound - array[i].lowerBound)), for: .empty)
                }
                if !result { return false }
            }
            return true
        }
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        guard !animations.isEmpty else { return }
        let state = options.isReversed == true ? state.reversed : state
        switch state {
        case .start:
            animations.reversed().forEach { $0.set(state: state) }
            interator.prevIndex = 0
        case .end:
            animations.forEach { $0.set(state: state) }
            interator.prevIndex = animations.count - 1
        case .progress(let k):
            let array = getProgresses(animations.map({ $0.modificators }), duration: fullDuration?.absolute ?? 0, options: .empty)
            let i = array.firstIndex(where: { k >= $0.lowerBound && k <= $0.upperBound }) ?? 0
            let finished = interator.prevIndex ?? 0
            let toFinish = i > finished || interator.prevIndex == nil ? animations.dropFirst(finished).prefix(i - finished) : []
            let p = interator.prevIndex ?? animations.count - 1
            let started = animations.count - p - 1
            let toStart = i < finished || interator.prevIndex == nil ? animations.dropLast(started).suffix((interator.prevIndex ?? p) - i) : []
            toFinish.forEach { $0.set(state: .end) }
            toStart.reversed().forEach { $0.set(state: .start) }
            animations[i].set(state: .progress((k - array[i].lowerBound) / (array[i].upperBound - array[i].lowerBound)))
            interator.prevIndex = i
        }
    }
    
    private func getOptions(for options: AnimationOptions) -> [AnimationOptions] {
        if let dur = options.duration?.absolute {
            return setDuration(duration: dur, options: options)
        } else {
            let full = fullDuration?.absolute ?? 0
            return setDuration(duration: full, options: options)
        }
    }
    
    private static func fullDuration(for array: [AnimationProviderProtocol]) -> AnimationDuration? {
        guard array.contains(where: { $0.modificators.duration?.absolute != 0 }) else { return nil }
        let dur = array.reduce(0, { $0 + ($1.modificators.duration?.absolute ?? 0) })
        var rel = min(1, array.reduce(0, { $0 + ($1.modificators.duration?.relative ?? 0) }))
        if rel == 0 {
            rel = Double(array.filter({ $0.modificators.duration == nil }).count) / Double(array.count)
        }
        rel = rel == 1 ? 0 : rel
        let full = dur / (1 - rel)
        return .absolute(full)
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions) -> [AnimationOptions] {
        guard full > 0 else { return [AnimationOptions](repeating: options.chain.duration[.absolute(0)], count: animations.count) }
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.modificators.duration?.absolute {
                k = absolute / full
            } else if let relative = anim.modificators.duration?.relative {
                k = relative
            }
            childrenRelativeTime += k ?? 0
            ks.append(k)
        }
        let cnt = ks.filter({ $0 == nil }).count
        let relativeK = cnt > 0 ? max(1, childrenRelativeTime) : childrenRelativeTime
        var add = (1 - min(1, childrenRelativeTime))
        if cnt > 0 {
            add /= Double(cnt)
        }
        var result: [AnimationOptions]
        if relativeK == 0 {
            result = [AnimationOptions](repeating: options.chain.duration[.absolute(full / Double(animations.count))], count: animations.count)
        } else {
            result = ks.map({ options.chain.duration[.absolute(full * ($0 ?? add) / relativeK)] })
        }
        setCurve(&result, duration: full, options: options)
        return result
    }
    
    private func setCurve(_ array: inout [AnimationOptions], duration: Double, options: AnimationOptions) {
        guard let fullCurve = options.curve, fullCurve != .linear else { return }
        let progresses = getProgresses(array, duration: duration, options: options)
        for i in 0..<animations.count {
            var (curve1, newDuration) = fullCurve.split(range: progresses[i])
            if let curve2 = animations[i].modificators.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
            array[i].duration = .absolute(duration * newDuration)
            array[i].curve = curve1
        }
    }

    private func getProgresses(_ array: [AnimationOptions], duration: Double, options: AnimationOptions) -> [ClosedRange<Double>] {
        guard !array.isEmpty else { return [] }
        guard duration > 0 else {
            return getProgresses(array)
        }
        var progresses: [ClosedRange<Double>] = []
        var dur = 0.0
        var start = 0.0
        
        for anim in array {
            if let rel = anim.duration?.relative {
                dur += min(1, max(0, rel))
            } else if let abs = anim.duration?.absolute {
                dur += abs / duration
            }
            let end = min(1, dur)
            progresses.append(start...end)
            start = end
        }
        progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
        return progresses
    }
    
    private func getProgresses(_ array: [AnimationOptions]) -> [ClosedRange<Double>] {
        let cnt = Double(array.filter({ $0.duration?.relative == nil }).count)
        let full = min(1, array.reduce(0, { $0 + ($1.duration?.relative ?? 0) }))
        let each = (1 - full) / cnt
        var progresses: [ClosedRange<Double>] = []
        var dur = 0.0
        var start = 0.0
        for anim in array {
            if let rel = anim.duration?.relative {
                dur += min(1, max(0, rel))
            } else {
                dur += each
            }
            let end = min(1, dur)
            progresses.append(start...end)
            start = end
        }
        progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
        return progresses
    }
    
}

fileprivate final class Interactor {
    var prevIndex: Int?
}
