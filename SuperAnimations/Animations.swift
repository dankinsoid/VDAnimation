//
//  Animations.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public struct Parallel: AnimatorProtocol {
    
    public init(_ animations: AnimatorProtocol...) {
    }
    
    public init(@AnimationBuilder _ animations: () -> ()) {
    }
    
    public init(@AnimationBuilder _ animations: () -> AnimatorProtocol) {
    }
    
    public init(@AnimationBuilder _ animations: () -> [AnimatorProtocol]) {
    }
    
    public func duration(_ value: Double) -> Parallel {
        return self
    }
}

public struct Sequential: AnimatorProtocol {
    
    public init(_ animations: AnimatorProtocol...) {
    }
    
    public init(@AnimationBuilder _ animations: () -> ()) {
    }
    
    public init(@AnimationBuilder _ animations: () -> AnimatorProtocol) {
    }
    
    public init(@AnimationBuilder _ animations: () -> [AnimatorProtocol]) {
        let view = UIView()
    }
    
    public func duration(_ value: Double) -> Sequential {
        return self
    }
}

public struct Animator: AnimatorProtocol {
    private var animator: UIViewPropertyAnimator
    
    init() {
        animator = UIViewPropertyAnimator()
    }
    
    public init(_ animation: @escaping () -> ()) {
        animator = UIViewPropertyAnimator(duration: 0, curve: .linear, animations: animation)
    }
    
    public init<T: AnyObject>(_ object: T, _ animation: @escaping (T) -> () -> ()) {
        self = Animator {[weak object] in
            guard let it = object else { return }
            animation(it)()
        }
    }
    
    public func duration(_ value: Double) -> Animator {
        return self
    }
}

public struct Interval: AnimatorProtocol, ExpressibleByFloatLiteral {
    public init(_ value: Double) {}
    
    public init(floatLiteral value: Double) {
        self = Interval(value)
    }
    
}

@_functionBuilder
public struct AnimationBuilder {
    
    public static func buildBlock() {
    }
    
    public static func buildBlock(_ animations: AnimatorProtocol...) -> [AnimatorProtocol] {
        return animations
    }
    
    public static func buildBlock(_ animation: AnimatorProtocol) -> AnimatorProtocol {
        return animation
    }
    
}

public protocol AnimatorProtocol {
    
}

public protocol ModifiableAnimator: AnimatorProtocol {
    
}

extension ModifiableAnimator {
    
    public subscript<T>(dynamicMember keyPath: KeyPath<AnimatorModifier<Self>, T>) -> Self {
        return AnimatorModifier<Self>(self).modify(keyPath)
    }
    
}

public struct AnimatorModifier<T: AnimatorProtocol> {
    
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    public func modify<M>(_ keyPath: KeyPath<AnimatorModifier<T>, M>) -> T {
        return value
    }
    
}
