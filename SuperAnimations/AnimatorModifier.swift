//
//  AnimatorModifier.swift
//  SuperAnimations
//
//  Created by Daniil on 21.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public struct AnimationParameters {
    static var `default`: AnimationParameters { AnimationParameters() }
    var completion: (UIViewAnimatingPosition) -> () = {_ in}
    var options: Animate.Options = .default
    var settedTiming: SettedTiming = .default
}

public struct SettedTiming {
    var duration: Animate.Duration?
    var curve: Animate.Timing.Curve?
    
    static let `default` = SettedTiming()
    
    public func or(_ other: SettedTiming) -> SettedTiming {
//        var _curve = curve ?? other.curve
//        if let par = curve, let oth = other.curve {
//            _curve = BezierCurve.between(par, oth)
//        }
        return SettedTiming(duration: duration ?? other.duration,
                     curve: curve ?? other.curve)
    }
    
}

extension AnimatorProtocol {

    public var scrubsLinearly: Bool { parameters.options.scrubsLinearly }
    public var isUserInteractionEnabled: Bool { parameters.options.isUserInteractionEnabled }
    public var isReversed: Bool { parameters.options.isReversed }
    public var isManualHitTestingEnabled: Bool { parameters.options.isManualHitTestingEnabled }
    public var isInterruptible: Bool { parameters.options.isInterruptible }
    public var restoreOnFinish: Bool { parameters.options.restoreOnFinish }
    
    public func start() {
        start {_ in}
    }
    
    public func duration(_ value: Double) -> Self {
        map(.absolute(value), at: \.settedTiming.duration)
    }
    
    public func duration(relative value: Double) -> Self {
        map(.relative(value), at: \.settedTiming.duration)
    }
    
    public func curve(_ value: Animate.Timing.Curve) -> Self {
        map(value, at: \.settedTiming.curve)
    }
    
    public func curve(_ p1: CGPoint, _ p2: CGPoint) -> Self {
        map(Animate.Timing.Curve(p1, p2), at: \.settedTiming.curve)
    }
    
    public func restoreOnFinish(_ value: Bool) -> Self {
        map(value, at: \.options.restoreOnFinish)
    }
    
    public func reversed() -> Self {
        map(true, at: \.options.isReversed)
    }
    
    public func autoreverse() -> Sequential {
        let first = self
        let second = reversed()
        return Sequential {
            first
            WithoutAnimation { first.stop(at: .start) }
            second
            WithoutAnimation { second.stop(at: .start) }
        }
    }
    
    public func `repeat`(_ count: Int?) -> RepeatAnimator<Self> {
        RepeatAnimator(on: self, count, parameters: .default)
    }
    
    public func onComplete(_ value: @escaping () -> ()) -> Self {
        let prev = self.parameters.completion
        let comlpetion: (UIViewAnimatingPosition) -> () = {
            prev($0)
            value()
        }
        return map(comlpetion, at: \.completion)
    }
    
    public func delay(_ value: Double) -> Sequential {
        return Sequential {
            Interval(value)
            self
        }
    }
    
    public func copy() -> Self {
        copy(with: parameters)
    }
    
    func removeCompletion() -> Self {
        map({_ in}, at: \.completion)
    }
    
    fileprivate func map<T>(_ value: T, at kp: WritableKeyPath<AnimationParameters, T>) -> Self {
        var parameters = self.parameters
        parameters[keyPath: kp] = value
        return copy(with: parameters)
    }

    func set(duration: Double?, curve: Animate.Timing.Curve?) {
        var dur: Animate.Duration?
        if let d = duration {
            dur = .absolute(d)
        }
        let prev = parameters.settedTiming
        parameters.settedTiming = SettedTiming(duration: dur, curve: curve).or(prev)
    }
    
}
