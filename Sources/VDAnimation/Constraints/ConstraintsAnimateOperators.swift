//
//  ConstraintsAnimations.swift
//  CA
//
//  Created by Daniil on 14.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//
import UIKit
import ConstraintsOperators

extension LayoutAttribute {
    
    public func ca<K: UILayoutable>(_ rhs: LayoutGradient<A, K, NSLayoutConstraint.Attribute>) -> ConstraintsAnimation<A> {
			ConstraintsAnimation(
				from: (self =| rhs.from).constraints,
				to: (self =| rhs.to).constraints,
				scale: { (self =| rhs.scale($0)).constraints }
			)
    }
    
	@available(iOS 13.0, *)
	public func ca(_ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<A> {
		ConstraintsAnimation(
			from: (self =| rhs.from).constraints,
			to: (self =| rhs.to).constraints,
			scale: { (self =| rhs.at($0)).constraints }
		)
	}
}

public func =|<T, C: UILayoutable, Y: UILayoutable, P: AttributeConvertable>(_ lhs: LayoutAttribute<T, C, P>, _ rhs: LayoutGradient<T, Y, NSLayoutConstraint.Attribute>) -> ConstraintsAnimation<T> {
    lhs.ca(rhs)
}

@available(iOS 13.0, *)
public func =|<T, C: UILayoutable, X: AttributeConvertable>(_ lhs: LayoutAttribute<T, C, X>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<T> {
    lhs.ca(rhs)
}

//
//public func =|<T, C: UILayoutable, T: AttributeConvertable>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .equal)
//}
//
//public func <=|<T, C: UILayoutable, T: AttributeConvertable>(_ lhs: LayoutAttribute<T, C>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C> {
//    return setup(lhs, rhs, relation: .lessThanOrEqual)
//}
//
//public func <=|<T, C: UILayoutable, T: AttributeConvertable>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .lessThanOrEqual)
//}
//
//public func >=|<T, C: UILayoutable, T: AttributeConvertable>(_ lhs: LayoutAttribute<T, C>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C> {
//    return setup(lhs, rhs, relation: .greaterThanOrEqual)
//}
//
//public func >=|<T, C: UILayoutable, T: AttributeConvertable>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .greaterThanOrEqual)
//}

@available(iOS 13.0, *)
public func *<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from * rhs, to: lhs.to * rhs, scale: { lhs.at($0) * rhs })
}

@available(iOS 13.0, *)
public func *<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutAttribute<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs * lhs.from, to: rhs * lhs.to, scale: { rhs * lhs.at($0) })
}

@available(iOS 13.0, *)
public func /<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutAttribute<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs / lhs.from, to: rhs / lhs.to, scale: { rhs / lhs.at($0) })
}

@available(iOS 13.0, *)
public func +<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from + rhs, to: lhs.to + rhs, scale: { lhs.at($0) + rhs })
}

@available(iOS 13.0, *)
public func +<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutAttribute<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs + lhs.from, to: rhs + lhs.to, scale: { rhs + lhs.at($0) })
}

@available(iOS 13.0, *)
public func -<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from - rhs, to: lhs.to - rhs, scale: { lhs.at($0) - rhs })
}

@available(iOS 13.0, *)
public func -<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutAttribute<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs - lhs.from, to: rhs - lhs.to, scale: { rhs - lhs.at($0) })
}

@available(iOS 13.0, *)
public func *<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from * rhs.from, to: lhs.to * rhs.to, scale: { lhs.at($0) * rhs.scale($0) })
}

@available(iOS 13.0, *)
public func *<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from * lhs.from, to: rhs.to * lhs.to, scale: { rhs.scale($0) * lhs.at($0) })
}

@available(iOS 13.0, *)
public func /<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from / lhs.from, to: rhs.to / lhs.to, scale: { rhs.scale($0) / lhs.at($0) })
}

@available(iOS 13.0, *)
public func +<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from + rhs.from, to: lhs.to + rhs.to, scale: { lhs.at($0) + rhs.scale($0) })
}

@available(iOS 13.0, *)
public func +<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from + lhs.from, to: rhs.to + lhs.to, scale: { rhs.scale($0) + lhs.at($0) })
}

@available(iOS 13.0, *)
public func -<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs.from - rhs.from, to: lhs.to - rhs.to, scale: { lhs.at($0) - rhs.scale($0) })
}

@available(iOS 13.0, *)
public func -<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from - lhs.from, to: rhs.to - lhs.to, scale: { rhs.scale($0) - lhs.at($0) })
}

public func *<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs * rhs.from, to: lhs * rhs.to, scale: { lhs * rhs.scale($0) })
}

public func *<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: CGFloat) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from * lhs, to: rhs.to * lhs, scale: { rhs.scale($0) * lhs })
}

public func /<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: CGFloat) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from / lhs, to: rhs.to / lhs, scale: { rhs.scale($0) / lhs })
}

public func +<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs + rhs.from, to: lhs + rhs.to, scale: { lhs + rhs.scale($0) })
}

public func +<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: CGFloat) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from + lhs, to: rhs.to + lhs, scale: { rhs.scale($0) + lhs })
}

public func -<A, C: UILayoutable, T: AttributeConvertable>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C, T>) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: lhs - rhs.from, to: lhs - rhs.to, scale: { lhs - rhs.scale($0) })
}

public func -<A, C: UILayoutable, T: AttributeConvertable>(_ rhs: LayoutGradient<A, C, T>, _ lhs: CGFloat) -> LayoutGradient<A, C, T> {
    LayoutGradient(from: rhs.from - lhs, to: rhs.to - lhs, scale: { rhs.scale($0) - lhs })
}
