//
//  Parallel.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Parallel: AnimatorProtocol {
    public var parameters: AnimationParameters
    public var state: UIViewAnimatingState = .inactive
    public var isRunning: Bool = false
    public var progress: Double = 0
    private var firstStart = true
    private var animations: [AnimatorProtocol]
    
    init(_ animations: [AnimatorProtocol], parameters: AnimationParameters = .default) {
        self.animations = animations
        self.parameters = parameters
    }
    
    public convenience init(animations: [AnimatorProtocol]) {
        self.init(animations, parameters: .default)
    }
    
    public convenience init(_ animations: AnimatorProtocol...) {
        self.init(animations)
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> ()) {
        animations()
        self.init()
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        configureChildren()
        animations.forEach { $0.start() }
    }
    
    public func pause() {
        animations.forEach { $0.pause() }
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        animations.forEach { $0.stop(at: position) }
    }
    
    public func copy(with parameters: AnimationParameters) -> Parallel {
        return Parallel(animations, parameters: parameters)
    }
    
    private func configureChildren() {
        guard firstStart else { return }
        setDuration()
        firstStart = false
    }
    
    private func setDuration() {
        if parameters.parentTiming.duration == nil {
            if let dur = parameters.userTiming.duration?.fixed {
                parameters.parentTiming.duration = .absolute(dur)
            } else {
                let dur = animations.reduce(0, { max($0, $1.timing.duration) })
                var rel = min(1, animations.reduce(0, { max($0, ($1.parameters.userTiming.duration?.relative ?? 0)) }))
                rel = rel == 1 ? 0 : rel
                let full = dur / (1 - rel)
                parameters.parentTiming.duration = .absolute(full)
            }
        }
        guard !animations.isEmpty else { return }
        let full = timing.duration
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.parameters.userTiming.duration?.fixed {
                k = absolute / full
            } else if let relative = anim.parameters.userTiming.duration?.relative {
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
        guard let fullCurve = parameters.parentTiming.curve ?? parameters.userTiming.curve else {
            for i in 0..<animations.count {
                animations[i].set(duration: durations[i], curve: nil)
            }
            return
        }
        for i in 0..<animations.count {
            var curve1 = fullCurve.split(at: 0.5).0
            if let curve2 = animations[i].parameters.userTiming.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
            animations[i].set(duration: durations[i], curve: curve1)
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
            let end = dur / timing.duration
            progresses.append(start...end)
            start = end
        }
    }
    
}
