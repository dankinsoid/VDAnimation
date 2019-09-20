//
//  Animations.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public enum AnimationType {
    case animator(AnimatorProtocol), modifier(AnimatorModifier)
}

public protocol AnimationTypeProtocol {
    var animationType: AnimationType { get }
}

public protocol AnimatorProtocol: AnimationTypeProtocol {
    var progress: Double { get set }
    var isRunning: Bool { get }
    var state: UIViewAnimatingState { get }
    var timing: Animator.Timing { get }
    var options: Animator.Options { get }
    func start()
    func pause()
    func stop(at position: UIViewAnimatingPosition)
    
    func duration(_ value: Double) -> Self
    func delay(_ value: Double) -> Self
    func curve(_ value: Animator.Timing.Curve) -> Self
    func onComplete(_ value: @escaping (UIViewAnimatingPosition) -> ()) -> Self
    func `repeat`(_ count: Int, autoreverse: Bool) -> Self
}

extension AnimatorProtocol {
    public var reverse: Self {
        return self.repeat(1, autoreverse: true)
    }
}

extension AnimatorProtocol {
    public var animationType: AnimationType { return .animator(self) }
}

public protocol AnimatorModifier: AnimationTypeProtocol {
    func modify(previous: AnimatorProtocol) -> AnimatorProtocol
    func modify(next: AnimatorProtocol) -> AnimatorProtocol
    func modify(previous: AnimatorProtocol, next: AnimatorProtocol) -> AnimatorProtocol
}

extension AnimatorModifier {
    public var animationType: AnimationType { return .modifier(self) }
}

extension Animator {
    
    public struct Options {
        public var scrubsLinearly: Bool
        public var isUserInteractionEnabled: Bool
        public var isReversed: Bool
        public var isManualHitTestingEnabled: Bool
        public var isInterruptible: Bool
        public var repeatCount: Int
        public var isAutoreversed: Bool
        
        public static let `default` = Options(
            scrubsLinearly: true,
            isUserInteractionEnabled: true,
            isReversed: false,
            isManualHitTestingEnabled: true,
            isInterruptible: true,
            repeatCount: 1,
            isAutoreversed: false
        )
    }
    
    public struct Timing {
        public var delay: Double
        public var duration: Double
        public var curve: Curve
        
        public static let `default` = Timing(
            delay: 0,
            duration: 0,
            curve: .linear
        )
        
        public struct Curve {
            public static let linear = Curve(point1: .zero, point2: CGPoint(x: 1, y: 1))
            var point1: CGPoint
            var point2: CGPoint
        }
    }
    
}

struct AnyAnimator {
    var animator: AnimatorProtocol
    var expectingTiming: Animator.Timing
    var givenTiming: Animator.Timing?
}
