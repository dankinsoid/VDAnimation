//
//  Animate.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Animate: AnimatorProtocol {
    public var state: UIViewAnimatingState { return animator?.state ?? .active }
    public let parameters: AnimationParameters
    public var isRunning: Bool { return animator?.isRunning ?? false }
    public var timing: Animate.Timing { .setted(parameters.settedTiming) }
    public var progress: Double {
        get { Double(animator?.fractionComplete ?? 0) }
        set { resetAnimatorIfNeeded().fractionComplete = CGFloat(newValue) }
    }
    private var animator: VDViewAnimator?
    private let animation: () -> ()
    private var springTiming: UISpringTimingParameters?
    
    private init(animation: @escaping () -> (), parameters: AnimationParameters, spring: UISpringTimingParameters?) {
        self.parameters = parameters
        self.animation = animation
        self.springTiming = spring
    }
    
    public convenience init(_ animation: @escaping () -> ()) {
        self.init(animation: animation, parameters: .default, spring: nil)
    }
    
    public convenience init<T: AnyObject>(_ object: T, _ animation: @escaping (T) -> () -> ()) {
        self.init {[weak object] in
            guard let it = object else { return }
            animation(it)()
        }
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        let anim = resetAnimatorIfNeeded()
        anim.startAnimation(completion)
    }
    
    public func start() {
        let anim = resetAnimatorIfNeeded()
        anim.startAnimation()
    }
    
    public func stop(at position: UIViewAnimatingPosition = .end) {
        if animator?.state != .stopped {
            animator?.stop()
        }
        animator?.finishAnimation(at: position)
    }
    
    public func pause() {
        animator?.pause()
    }
    
    private func resetAnimatorIfNeeded() -> VDViewAnimator {
        if let anim = animator, anim.state == .active {
            return anim
        }
        return resetAnimator()
    }
    
    private func resetAnimator() -> VDViewAnimator {
        let provider = VDTimingProvider(bezier: timing.curve, spring: springTiming)
        let _animator = VDViewAnimator(duration: timing.duration, timingParameters: provider)
        _animator.addAnimations(animation)
        _animator.addCompletion(parameters.completion)
        animator = _animator
        setOptions()
        return _animator
    }
    
    private func setOptions() {
        animator?.isInterruptible = isInterruptible
        animator?.isManualHitTestingEnabled = isManualHitTestingEnabled
        if isReversed, let an = animator {
            an.fractionComplete = 1 - an.fractionComplete
        }
        animator?.isReversed = isReversed
        animator?.reverseOnComplete = restoreOnFinish
        if animator?.state != .active {
            animator?.isUserInteractionEnabled = isUserInteractionEnabled
            animator?.scrubsLinearly = scrubsLinearly
        }
    }
    
    public func copy(with parameters: AnimationParameters) -> Animate {
        return Animate(animation: animation, parameters: parameters, spring: springTiming)
    }
    
    public func withoutAnimation() -> WithoutAnimation {
        return WithoutAnimation(animation)
    }
    
    public func spring(_ dampingRatio: CGFloat = 0.3) -> Animate {
        let spring = UISpringTimingParameters(dampingRatio: dampingRatio)
        return Animate(animation: animation, parameters: parameters, spring: spring)
    }
    
}

@objc(_TtC15SuperAnimationsVDTimingProvider)
fileprivate class VDTimingProvider: NSObject, UITimingCurveProvider {
    let timingCurveType: UITimingCurveType
    let cubicTimingParameters: UICubicTimingParameters?
    let springTimingParameters: UISpringTimingParameters?
    
    init(bezier: BezierCurve?, spring: UISpringTimingParameters?) {
        var isBuiltin = false
        if let bezier = bezier {
            if let builtin = bezier.builtin {
                cubicTimingParameters = UICubicTimingParameters(animationCurve: builtin)
                isBuiltin = true
            } else {
                cubicTimingParameters =  UICubicTimingParameters(controlPoint1: bezier.point1, controlPoint2: bezier.point2)
            }
        } else if spring == nil {
            cubicTimingParameters = UICubicTimingParameters(animationCurve: .linear)
            isBuiltin = true
        } else {
            cubicTimingParameters = nil
        }
       springTimingParameters = spring
        switch (bezier, spring) {
        case (.some, .some): timingCurveType = .composed
        case (.some, .none): timingCurveType = isBuiltin ? .builtin : .cubic
        case (.none, .some): timingCurveType = .spring
        case (.none, .none): timingCurveType = .cubic
        }
    }
    
    init(timing: UITimingCurveType, cubic: UICubicTimingParameters?, spring: UISpringTimingParameters?) {
        self.timingCurveType = timing
        self.cubicTimingParameters = cubic
        self.springTimingParameters = spring
    }
    
    required init?(coder: NSCoder) {
        timingCurveType = UITimingCurveType(rawValue: coder.decodeInteger(forKey: Keys.timingCurveType)) ?? .cubic
        cubicTimingParameters = coder.decodeObject(of: UICubicTimingParameters.self, forKey: Keys.cubicTimingParameters)
        springTimingParameters = coder.decodeObject(of: UISpringTimingParameters.self, forKey: Keys.springTimingParameters)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(timingCurveType.rawValue, forKey: Keys.timingCurveType)
        coder.encode(cubicTimingParameters, forKey: Keys.cubicTimingParameters)
        coder.encode(springTimingParameters, forKey: Keys.springTimingParameters)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return VDTimingProvider(timing: timingCurveType, cubic: cubicTimingParameters, spring: springTimingParameters)
    }
    
    fileprivate struct Keys {
        static let timingCurveType = "timingCurveType"
        static let cubicTimingParameters = "cubicTimingParameters"
        static let springTimingParameters = "springTimingParameters"
    }
    
}
