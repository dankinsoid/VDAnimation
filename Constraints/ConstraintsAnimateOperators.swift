//
//  ConstraintsAnimations.swift
//  CA
//
//  Created by Daniil on 14.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//
import UIKit
//import ConstraintsOperators

extension LayoutAttribute {
    
    public func ca<K: ConstraintsCreator>(_ rhs: LayoutGradient<A, K>) -> ConstraintsAnimation<A, C, K> where C.Second == K.First, K.A == NSLayoutConstraint.Attribute {
        ConstraintsAnimation(from: self.equal(to: rhs.from), to: self.equal(to: rhs.to), scale: { self.equal(to: rhs.scale($0)) })
    }
    
}

extension LayoutAttribute where C.Constraint == NSLayoutConstraint, C.Second == C.First, C.A == NSLayoutConstraint.Attribute {
    
    public func ca(_ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<A, C, C> {
        ConstraintsAnimation(from: self.equal(to: rhs.from), to: self.equal(to: rhs.to), scale: { self.equal(to: rhs.at($0)) })
    }
    
}

public func =|<T, C: ConstraintsCreator, K: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>, _ rhs: LayoutGradient<T, K>) -> ConstraintsAnimation<T, C, K> where C.Second == K.First, K.A == NSLayoutConstraint.Attribute, C.Constraint == NSLayoutConstraint {
    lhs.ca(rhs)
}

public func =|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<T, C, C> where C.Constraint == NSLayoutConstraint {
    lhs.ca(rhs)
}

//
//public func =|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .equal)
//}
//
//public func <=|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C> {
//    return setup(lhs, rhs, relation: .lessThanOrEqual)
//}
//
//public func <=|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .lessThanOrEqual)
//}
//
//public func >=|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C> {
//    return setup(lhs, rhs, relation: .greaterThanOrEqual)
//}
//
//public func >=|<T, C: ConstraintsCreator>(_ lhs: LayoutAttribute<T, C>?, _ rhs: Gradient<CGFloat>) -> ConstraintsAnimation<C>? {
//    return _setup(lhs, rhs, relation: .greaterThanOrEqual)
//}

public func *<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from * rhs, to: lhs.to * rhs, scale: { lhs.at($0) * rhs })
}

public func *<A, C: ConstraintsCreator>(_ rhs: LayoutAttribute<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs * lhs.from, to: rhs * lhs.to, scale: { rhs * lhs.at($0) })
}

public func /<A, C: ConstraintsCreator>(_ rhs: LayoutAttribute<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs / lhs.from, to: rhs / lhs.to, scale: { rhs / lhs.at($0) })
}

public func +<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from + rhs, to: lhs.to + rhs, scale: { lhs.at($0) + rhs })
}

public func +<A, C: ConstraintsCreator>(_ rhs: LayoutAttribute<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs + lhs.from, to: rhs + lhs.to, scale: { rhs + lhs.at($0) })
}

public func -<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutAttribute<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from - rhs, to: lhs.to - rhs, scale: { lhs.at($0) - rhs })
}

public func -<A, C: ConstraintsCreator>(_ rhs: LayoutAttribute<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs - lhs.from, to: rhs - lhs.to, scale: { rhs - lhs.at($0) })
}

public func *<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from * rhs.from, to: lhs.to * rhs.to, scale: { lhs.at($0) * rhs.scale($0) })
}

public func *<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from * lhs.from, to: rhs.to * lhs.to, scale: { rhs.scale($0) * lhs.at($0) })
}

public func /<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from / lhs.from, to: rhs.to / lhs.to, scale: { rhs.scale($0) / lhs.at($0) })
}

public func +<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from + rhs.from, to: lhs.to + rhs.to, scale: { lhs.at($0) + rhs.scale($0) })
}

public func +<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from + lhs.from, to: rhs.to + lhs.to, scale: { rhs.scale($0) + lhs.at($0) })
}

public func -<A, C: ConstraintsCreator>(_ lhs: Gradient<CGFloat>, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs.from - rhs.from, to: lhs.to - rhs.to, scale: { lhs.at($0) - rhs.scale($0) })
}

public func -<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: Gradient<CGFloat>) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from - lhs.from, to: rhs.to - lhs.to, scale: { rhs.scale($0) - lhs.at($0) })
}

public func *<A, C: ConstraintsCreator>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs * rhs.from, to: lhs * rhs.to, scale: { lhs * rhs.scale($0) })
}

public func *<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: CGFloat) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from * lhs, to: rhs.to * lhs, scale: { rhs.scale($0) * lhs })
}

public func /<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: CGFloat) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from / lhs, to: rhs.to / lhs, scale: { rhs.scale($0) / lhs })
}

public func +<A, C: ConstraintsCreator>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs + rhs.from, to: lhs + rhs.to, scale: { lhs + rhs.scale($0) })
}

public func +<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: CGFloat) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from + lhs, to: rhs.to + lhs, scale: { rhs.scale($0) + lhs })
}

public func -<A, C: ConstraintsCreator>(_ lhs: CGFloat, _ rhs: LayoutGradient<A, C>) -> LayoutGradient<A, C> {
    LayoutGradient(from: lhs - rhs.from, to: lhs - rhs.to, scale: { lhs - rhs.scale($0) })
}

public func -<A, C: ConstraintsCreator>(_ rhs: LayoutGradient<A, C>, _ lhs: CGFloat) -> LayoutGradient<A, C> {
    LayoutGradient(from: rhs.from - lhs, to: rhs.to - lhs, scale: { rhs.scale($0) - lhs })
}
