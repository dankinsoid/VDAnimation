//
//  Animator.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Animator: AnimatorProtocol {
    public var state: UIViewAnimatingState { return animator.state }
    private(set) public var timing: Timing
    private(set) public var options: Options
    private var completion: (UIViewAnimatingPosition) -> ()
    public var isRunning: Bool { return animator.isRunning }
    private var copy: Animator {
        let result = Animator(animation: animation, options: options, timing: timing, completion: completion)
        result.animator = animator
        return result
    }
    
    public var progress: Double {
        get { return Double(animator.fractionComplete) }
        set { return animator.fractionComplete = CGFloat(newValue) }
    }
    private var animator: UIViewPropertyAnimator
    
    private let animation: () -> ()
    
    private init(animation: @escaping () -> (), options: Options, timing: Timing, completion: @escaping (UIViewAnimatingPosition) -> ()) {
        self.options = options
        self.timing = timing
        self.completion = completion
        self.animator = UIViewPropertyAnimator()
        self.animation = animation
        resetAnimator()
    }
    
    public convenience init(_ animation: @escaping () -> ()) {
        self.init(animation: animation, options: .default, timing: .default, completion: {_ in})
    }
    
    public convenience init<T: AnyObject>(_ object: T, _ animation: @escaping (T) -> () -> ()) {
        self.init {[weak object] in
            guard let it = object else { return }
            animation(it)()
        }
    }
    
    public func duration(_ value: TimeInterval) -> Animator {
        let result = self
        return result
    }
    
    public func start() {
        
        animator.startAnimation()
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        
    }
    
    public func pause() {
        animator.pauseAnimation()
    }
    
    public func stop() {
        animator.stopAnimation(false)
    }
    
    public func delay(_ value: Double) -> Animator {
        return map(value, at: \.timing.delay)
    }
    
    public func curve(_ value: Animator.Timing.Curve) -> Animator {
        return map(value, at: \.timing.curve)
    }
    
    public func onComplete(_ value: @escaping (UIViewAnimatingPosition) -> ()) -> Animator {
        return copy {
            let comp = $0.completion
            $0.completion = {
                comp($0)
                value($0)
            }
        }
    }
    
    public func `repeat`(_ count: Int, autoreverse: Bool) -> Animator {
        return map(count, at: \.options.repeatCount).map(autoreverse, at: \.options.isAutoreversed)
    }
    
    private func map<T>(_ value: T, at keyPath: WritableKeyPath<Animator, T>) -> Animator {
        var result = copy
        result[keyPath: keyPath] = value
        return result
    }
    
    private func copy(_ modify: (inout Animator) -> ()) -> Animator {
        var result = copy
        modify(&result)
        return result
    }
    
    private func resetAnimator() {
        self.animator = UIViewPropertyAnimator(duration: timing.duration, controlPoint1: timing.curve.point1, controlPoint2: timing.curve.point2, animations: animation)
        self.animator.pausesOnCompletion = false
    }
    
}
