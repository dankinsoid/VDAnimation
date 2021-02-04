//
//  ConstraintAnimation.swift
//  CA
//
//  Created by Daniil on 14.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit
import ConstraintsOperators

public struct ConstraintsAnimation<T, C: ConstraintsCreator, K: ConstraintsCreator>: VDAnimationProtocol where C.Second == K.First, K.A == NSLayoutConstraint.Attribute, C.Constraint == NSLayoutConstraint {
    let from: () -> C.Constraint
    let to: () -> C.Constraint
    let scale: (Double) -> C.Constraint
    
    init(from: @escaping @autoclosure () -> C.Constraint, to: @escaping @autoclosure () -> C.Constraint, scale: @escaping (Double) -> C.Constraint) {
        self.from = from
        self.to = to
        self.scale = scale
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        set(position: .start, for: options)
        return Animate {
            let constraint = options.isReversed ? self.from() : self.to()
            constraint.didUpdate()
        }.start(with: options.chain.autoreverseStep[nil], completion)
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        let state = options.isReversed ? position.reversed : position
        let constraint: NSLayoutConstraint
        switch state {
        case .start:
            constraint = from()
        case .progress(let k):
            constraint = scale(k)
        case .end:
            constraint = to()
        }
        constraint.didUpdate()
    }
    
}

public struct LayoutGradient<A, C: ConstraintsCreator> {
    let from: LayoutAttribute<A, C>
    let to: LayoutAttribute<A, C>
    let scale: (Double) -> LayoutAttribute<A, C>
}
