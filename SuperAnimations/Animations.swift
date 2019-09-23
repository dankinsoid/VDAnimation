//
//  Animations.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

//public enum AnimationType {
//    case animator(AnimatorProtocol), modifier(AnimatorModifier)
//}
//
//public protocol AnimationTypeProtocol {
//    var animationType: AnimationType { get }
//}

public protocol AnimatorProtocol {
    var progress: Double { get set }
    var isRunning: Bool { get }
    var state: UIViewAnimatingState { get }
    var timing: Animator.Timing { get }
    var parameters: AnimationParameters { get }
    func copy(with parameters: AnimationParameters) -> Self
    func start(_ completion: @escaping (UIViewAnimatingPosition) -> ())
    func start()
    func pause()
    func stop(at position: UIViewAnimatingPosition)
    
}

//extension AnimatorProtocol {
//    public var animationType: AnimationType { return .animator(self) }
//}

//public protocol AnimatorModifier: AnimationTypeProtocol {
//    func modify(previous: AnimatorProtocol) -> AnimatorProtocol
//    func modify(next: AnimatorProtocol) -> AnimatorProtocol
//    func modify(previous: AnimatorProtocol, next: AnimatorProtocol) -> AnimatorProtocol
//}
//
//extension AnimatorModifier {
//    public var animationType: AnimationType { return .modifier(self) }
//}

extension Animator {
    
    public struct Options {
        public var scrubsLinearly: Bool
        public var isUserInteractionEnabled: Bool
        public var isReversed: Bool
        public var isManualHitTestingEnabled: Bool
        public var isInterruptible: Bool
        public var restoreOnFinish: Bool
        
        public static let `default` = Options(
            scrubsLinearly: true,
            isUserInteractionEnabled: true,
            isReversed: false,
            isManualHitTestingEnabled: true,
            isInterruptible: true,
            restoreOnFinish: false
        )
    }
    
    enum Duration {
        case absolute(Double), relative(Double)
        
        var fixed: Double? {
            if case .absolute(let value) = self {
                return value
            }
            return nil
        }
    }
    
    public struct Timing {
        public var duration: Double
        public var curve: Curve
        
        public static let `default` = Timing(
            duration: 0,
            curve: .linear
        )
        
        static func setted(_ timing: SettedTiming) -> Timing {
            return Timing(duration: timing.duration ?? 0, curve: timing.curve ?? .linear)
        }
        
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

protocol _Modified {
    var copy: Self { get }
    func map<T>(_ value: T, at keyPath: WritableKeyPath<Self, T>) -> Self
    func copy(_ modify: (inout Self) -> ()) -> Self
}

extension _Modified {

    func map<T>(_ value: T, at keyPath: WritableKeyPath<Self, T>) -> Self {
        var result = copy
        result[keyPath: keyPath] = value
        return result
    }

    func copy(_ modify: (inout Self) -> ()) -> Self {
        var result = copy
        modify(&result)
        return result
    }
    
}

