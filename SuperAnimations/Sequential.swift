//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Sequential: AnimatorProtocol {
    public var parameters: AnimationParameters = .default
    public var state: UIViewAnimatingState { currentAnimation?.state ?? .inactive }
    public var isRunning: Bool { currentAnimation?.isRunning ?? false }
    public var progress: Double {
        get { getProgress() }
        set { setProgress(newValue) }
    }
    var animations: [AnimatorProtocol]
    private var currentIndex = 0
    private var firstStart = true
    public var timing: Animate.Timing {
        return getTiming()
    }
    private var _timing: Animate.Timing?
    private var currentAnimation: AnimatorProtocol? {
        if currentIndex < animations.count, currentIndex >= 0 {
            return isReversed ? animations[currentIndex].reversed() : animations[currentIndex]
        }
        return nil
    }
    
    init(_ animations: [AnimatorProtocol], parameters: AnimationParameters) {
        self.animations = animations
        self.parameters = parameters
        configureChildren()
    }
    
    public convenience init(_ animations: [AnimatorProtocol]) {
        self.init(animations, parameters: .default)
    }
    
    public convenience init(_ animations: AnimatorProtocol...) {
        self.init(animations)
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        configureChildren()
        guard !isRunning else {
            let c = parameters.completion
            parameters.completion = {[weak self] in
                c($0)
                completion($0)
                self?.parameters.completion = c
            }
            return
        }
        if isReversed {
            (0..<(animations.count)).forEach {
                animations[$0].progress = 1
            }
        }
        _start(completion)
    }
    
    private func _start(_ completion: ((UIViewAnimatingPosition) -> ())?) {
        guard !animations.isEmpty, currentIndex < animations.count else {
            parameters.completion(.end)
            completion?(.end)
            return
        }
        currentAnimation?.start {
            guard $0 != .current else {
                self.parameters.completion($0)
                completion?($0)
                return
            }
            self.currentIndex += 1
            self._start(completion)
        }
    }
    
    public func pause() {
        currentAnimation?.pause()
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        currentAnimation?.stop(at: position)
        switch position {
        case .start:    currentIndex = 0
        case .end:      currentIndex = animations.count
        default:        break
        }
    }
    
    public func copy(with parameters: AnimationParameters) -> Sequential {
        return Sequential(animations, parameters: parameters)
    }
    
    private func getProgress() -> Double {
        configureChildren()
        guard animations.count != 1 else { return currentAnimation?.progress ?? 0 }
        guard !animations.isEmpty else { return 0 }
        guard currentIndex < animations.count else { return 1 }
        let full = animations.reduce(0, { $0 + $1.timing.duration })
        guard full > 0 else { return currentAnimation?.progress ?? 1 }
        var current = (currentAnimation?.progress ?? 0) * (currentAnimation?.timing.duration ?? 0)
        current += animations.prefix(currentIndex).reduce(0, { $0 + $1.timing.duration })
        return current / full
    }
    
    private func setProgress(_ value: Double) {
        guard !animations.isEmpty else { return }
        configureChildren()
        let full = animations.reduce(0, { $0 + $1.timing.duration })
        guard full > 0 else {
            currentIndex = max(0, min(currentIndex, animations.count - 1))
            animations[currentIndex].progress = value
            return
        }
        let expected = value * full
        var i = 0
        var dur = 0.0
        while i < animations.count {
            guard dur + animations[i].timing.duration < expected else { break }
            dur += animations[i].timing.duration
            i += 1
        }
        let newValue = max(0, min(1, (expected - dur) / animations[i].timing.duration))
        guard i != currentIndex else {
            animations[i].progress = newValue
            return
        }
        currentIndex = i
        animations[i].stop(at: .current)
        if i < animations.count - 1 {
            for j in (i + 1)..<animations.count {
                animations[j].progress = 0
                animations[j].stop(at: .start)
            }
        }
        if i > 0 {
            for j in 0..<i {
                animations[j].progress = 1
                animations[j].stop(at: .end)
            }
        }
        guard i < animations.count else {
            return
        }
        animations[i].progress = newValue
    }
    
    func configureChildren() {
        guard firstStart else { return }
        setDuration()
        firstStart = false
    }
    
    private func getTiming() -> Animate.Timing {
        if let dur = parameters.settedTiming.duration?.fixed {
            return Animate.Timing(duration: dur, curve: parameters.settedTiming.curve ?? .linear)
        } else if let computed = _timing {
            return computed
        } else {
            let dur = animations.reduce(0, { $0 + $1.timing.duration })
            var rel = min(1, animations.reduce(0, { $0 + ($1.parameters.settedTiming.duration?.relative ?? 0) }))
            rel = rel == 1 ? 0 : rel
            let full = dur / (1 - rel)
            let result = Animate.Timing(duration: full, curve: parameters.settedTiming.curve ?? .linear)
            _timing = result
            return result
        }
    }
    
    private func setDuration() {
        guard !animations.isEmpty else { return }
        let full = timing.duration
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.parameters.settedTiming.duration?.fixed {
                k = absolute / full
            } else if let relative = anim.parameters.settedTiming.duration?.relative {
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
        var k = relativeK == 0 ? [Double](repeating: 1 / Double(animations.count), count: animations.count) : ks.map({ ($0 ?? add) / relativeK })
        for i in 0..<k.count {
            k[i] *= full
        }
        setCurve(k)
    }
    
    private var progresses: [ClosedRange<Double>] = []
    
    private func setCurve(_ durations: [Double]) {
        setProgresses(durations)
        guard let fullCurve = parameters.settedTiming.curve, fullCurve != .linear else {
            for i in 0..<animations.count {
                animations[i].set(duration: durations[i], curve: nil)
            }
            return
        }
//        var newD: [String] = [timing.curve.exportWith(name: "common")]
//        var newT: [Double] = []
        for i in 0..<animations.count {
            var (curve1, newDuration) = fullCurve.split(range: progresses[i])
            if let curve2 = animations[i].parameters.settedTiming.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
//            newD.append(curve1.exportWith(name: "curve\(i)"))
//            newT.append(newDuration)
            animations[i].set(duration: timing.duration * newDuration, curve: curve1)
        }
    }
    
    private func setProgresses(_ durations: [Double]) {
        progresses = []
        guard !animations.isEmpty else { return }
        guard timing.duration > 0 else {
            progresses = Array(repeating: 0...0, count: durations.count)
            return
        }
        var dur = 0.0
        var start = 0.0
        for anim in durations {
            dur += anim
            let end = min(1, dur / timing.duration)
            progresses.append(start...end)
            start = end
        }
        progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
    }
    
}
