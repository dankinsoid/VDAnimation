//
//  Animator.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Animator: AnimatorProtocol {
    public var state: UIViewAnimatingState { return animator?.state ?? .active }
    public var parameters: AnimationParameters
    public var isRunning: Bool { return animator?.isRunning ?? false }
    public var progress: Double {
        get { Double(animator?.fractionComplete ?? 0) }
        set { resetAnimatorIfNeeded().fractionComplete = CGFloat(newValue) }
    }
    private var animator: VDViewAnimator?
    private let animation: () -> ()
    
    private init(animation: @escaping () -> (), parameters: AnimationParameters) {
        self.parameters = parameters
        self.animation = animation
    }
    
    public convenience init(_ animation: @escaping () -> ()) {
        self.init(animation: animation, parameters: .default)
    }
    
    public convenience init<T: AnyObject>(_ object: T, _ animation: @escaping (T) -> () -> ()) {
        self.init {[weak object] in
            guard let it = object else { return }
            animation(it)()
        }
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        let c = parameters.completion
        parameters.completion = {[weak self] in
            c($0)
            completion($0)
            self?.parameters.completion = c
        }
        start()
    }
    
    public func start() {
        let anim = resetAnimatorIfNeeded()
        anim.startAnimation(afterDelay: timing.delay)
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
        let _animator = VDViewAnimator(duration: timing.duration, controlPoint1: timing.curve.point1, controlPoint2: timing.curve.point2, animations: animation)
//        _animator.pausesOnCompletion = false
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
        animator?.isUserInteractionEnabled = isUserInteractionEnabled
        animator?.scrubsLinearly = scrubsLinearly
    }
    
    public func copy(with parameters: AnimationParameters) -> Animator {
        return Animator(animation: animation, parameters: parameters)
    }
    
}
