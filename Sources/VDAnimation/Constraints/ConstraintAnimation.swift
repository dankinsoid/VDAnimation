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

public struct ConstraintsAnimation<T>: VDAnimationProtocol {
    let from: () -> [NSLayoutConstraint]
    let to: () -> [NSLayoutConstraint]
    let scale: (Double) -> [NSLayoutConstraint]
    
    init(from: @escaping @autoclosure () -> [NSLayoutConstraint], to: @escaping @autoclosure () -> [NSLayoutConstraint], scale: @escaping (Double) -> [NSLayoutConstraint]) {
        self.from = from
        self.to = to
        self.scale = scale
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
			set(position: .start, for: options, execute: true)
        return Animate {
            let constraint = options.isReversed ? self.from() : self.to()
					constraint.forEach { $0.didUpdate() }
        }.start(with: options.chain.autoreverseStep[nil], completion)
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
        let state = options.isReversed ? position.reversed : position
        let constraint: [NSLayoutConstraint]
        switch state {
        case .start:
            constraint = from()
        case .progress(let k):
            constraint = scale(k)
        case .end:
            constraint = to()
				case .current:
					return
        }
			constraint.forEach { $0.didUpdate() }
    }
    
}

public struct LayoutGradient<A, B: UILayoutable, C: AttributeConvertable> {
    let from: LayoutAttribute<A, B, C>
    let to: LayoutAttribute<A, B, C>
    let scale: (Double) -> LayoutAttribute<A, B, C>
}
