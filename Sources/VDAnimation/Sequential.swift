//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation
import VDKit

public struct Sequential: VDAnimationProtocol {
    private let animations: [VDAnimationProtocol]
    public var modified: ModifiedAnimation {
        ModifiedAnimation(options: AnimationOptions.empty.chain.duration[fullDuration], animation: self)
    }
    private let fullDuration: AnimationDuration?
    private let interator: Interactor
    
    public init(_ animations: [VDAnimationProtocol]) {
        self.animations = animations
        self.fullDuration = Sequential.fullDuration(for: animations)
        self.interator = Interactor()
    }
    
    public init(_ animations: VDAnimationProtocol...) {
        self = .init(animations)
    }
    
    public init(@AnimatorBuilder _ animations: () -> [VDAnimationProtocol]) {
        self = .init(animations())
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        guard !animations.isEmpty else {
            completion(true)
            return .end
        }
        guard animations.count > 1 else {
            return animations[0].start(with: options, completion)
        }
        let array = getOptions(for: options)
        let result = MutableDelegate()
        start(index: 0, delegate: result, options: array, reversed: options.autoreverseStep == .back, completion)
        return delegate(for: result)
    }
    
    private func delegate(for mutable: MutableDelegate) -> AnimationDelegate {
        AnimationDelegate {
            mutable.delegate.stop(.start)
            self.set(position: $0, for: .empty)
            return $0
        }
    }
    
    private func start(index: Int, delegate: MutableDelegate, options: [AnimationOptions], reversed: Bool, _ completion: @escaping (Bool) -> ()) {
        interator.prevIndex = nil
        guard index < animations.count else {
            completion(true)
            delegate.delegate = .end
            return
        }
        let i = reversed ? animations.count - index - 1 : index
        delegate.delegate = animations[i].start(with: options[i]) {
            guard $0 else {
                return completion(false)
            }
            self.start(index: index + 1, delegate: delegate, options: options, reversed: reversed, completion)
        }
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        guard !animations.isEmpty else { return }
        let position = options.isReversed == true ? position.reversed : position
        switch position {
        case .start:
            animations.reversed().forEach { $0.set(position: position) }
            interator.prevIndex = 0
        case .end:
            animations.forEach { $0.set(position: position) }
            interator.prevIndex = animations.count - 1
        case .progress(let k):
            let array = getProgresses(animations.map({ $0.options }), duration: (options.duration ?? fullDuration)?.absolute ?? 0, options: options)
            let i = array.firstIndex(where: { k >= $0.lowerBound && k <= $0.upperBound }) ?? 0
            let finished = interator.prevIndex ?? 0
            let toFinish = i > finished || interator.prevIndex == nil ? animations.dropFirst(finished).prefix(i - finished) : []
            let p = interator.prevIndex ?? animations.count - 1
            let started = animations.count - p - 1
            let toStart = i < finished || interator.prevIndex == nil ? animations.dropLast(started).suffix((interator.prevIndex ?? p) - i) : []
            toFinish.forEach { $0.set(position: .end) }
            toStart.reversed().forEach { $0.set(position: .start) }
            if array[i].upperBound == array[i].lowerBound {
                animations[i].set(position: .progress(1))
            } else {
                animations[i].set(position: .progress((k - array[i].lowerBound) / (array[i].upperBound - array[i].lowerBound)))
            }
            interator.prevIndex = i
				case .current:
					animations.forEach { $0.set(position: .current) }
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
    
    private static func fullDuration(for array: [VDAnimationProtocol]) -> AnimationDuration? {
        guard array.contains(where: {
            $0.options.duration?.absolute != nil && !$0.options.isInstant
        }) else { return nil }
        let dur = array.reduce(0, { $0 + ($1.options.duration?.absolute ?? 0) })
        var rel = min(1, array.reduce(0, { $0 + ($1.options.duration?.relative ?? 0) }))
        if rel == 0 {
            rel = Double(array.filter({ $0.options.duration == nil }).count) / Double(array.count)
        }
        rel = rel == 1 ? 0 : rel
        let full = dur / (1 - rel)
        return .absolute(full)
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions) -> [AnimationOptions] {
        guard full > 0 else {
            return [AnimationOptions](repeating: options.chain.duration[.absolute(0)], count: animations.count)

        }
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.options.duration?.absolute {
                k = absolute / full
            } else if let relative = anim.options.duration?.relative {
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
            if let curve2 = animations[i].options.curve {
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
        let cnt = Double(array.filter({ $0.duration == nil }).count)
			let full: Double = array.map { $0.duration?.relative ?? ($0.duration?.absolute ?? 0) / duration }.reduce(0, +)
        let remains = max(0, 1 - full) / max(1, cnt)
        for anim in array {
            if let rel = anim.duration?.relative {
                dur += min(1, max(0, rel))
            } else if let abs = anim.duration?.absolute {
                dur += abs / duration
            } else {
                dur += remains
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
