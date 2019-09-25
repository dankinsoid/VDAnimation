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
    var options: Animator.Options = .default
    var userTiming: SettedTiming = .default
    var parentTiming: SettedTiming = .default
}

public struct SettedTiming {
    var duration: Animator.Duration?
    var curve: Animator.Timing.Curve?
    
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
    public var timing: Animator.Timing { .setted(parameters.parentTiming.or(parameters.userTiming)) }
    
    public func start() {
        start {_ in}
    }
    
    public func `repeat`(_ count: Int?) -> RepeatAnimator<Self> {
        RepeatAnimator(on: self, count, parameters: .default)
    }
    
    public func autoreverse() -> Sequential {
        Sequential {
            self
            self.reversed()
        }
    }
    
    public func duration(_ value: Double) -> Self {
        map(.absolute(value), at: \.userTiming.duration)
    }
    
    public func relativeDuration(_ value: Double) -> Self {
        map(.relative(value), at: \.userTiming.duration)
    }
    
    public func curve(_ value: Animator.Timing.Curve) -> Self {
        map(value, at: \.userTiming.curve)
    }
    
    public func restoreOnFinish(_ value: Bool) -> Self {
        map(value, at: \.options.restoreOnFinish)
    }
    
    public func onComplete(_ value: @escaping (UIViewAnimatingPosition) -> ()) -> Self {
        let prev = self.parameters.completion
        let comlpetion: (UIViewAnimatingPosition) -> () = {
            prev($0)
            value($0)
        }
        return map(comlpetion, at: \.completion)
    }
    
    public func reversed() -> Self {
        map(true, at: \.options.isReversed)
    }
    
    func removeCompletion() -> Self {
        map({_ in}, at: \.completion)
    }
    
    private func map<T>(_ value: T, at kp: WritableKeyPath<AnimationParameters, T>) -> Self {
        var parameters = self.parameters
        parameters[keyPath: kp] = value
        return copy(with: parameters)
    }

    func set(duration: Double?, curve: Animator.Timing.Curve?) {
        var dur: Animator.Duration?
        if let d = duration {
            dur = .absolute(d)
        }
        parameters.parentTiming = SettedTiming(duration: dur, curve: curve).or(parameters.userTiming)
    }
    
}
