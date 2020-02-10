//
//  Operators.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension AnimationProviderProtocol {
    
    public func duration(_ value: TimeInterval) -> AnimationProviderProtocol {
        asModifier.chain.modificators.duration[.absolute(value)]
    }
    
    public func duration(relative value: Double) -> AnimationProviderProtocol {
        asModifier.chain.modificators.duration[.relative(value)]
    }
    
    public func curve(_ value: BezierCurve) -> AnimationProviderProtocol {
        asModifier.chain.modificators.curve[value]
//        let result = asModifier
//        return result.chain.modificators.curve[CA.curve(value, result.modificators.curve)]
    }
    
    public func curve<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) -> AnimationProviderProtocol {
        asModifier.chain.modificators.curve[.init(p1, p2)]
    }
    
    public func `repeat`(_ count: Int) -> AnimationProviderProtocol {
        RepeatAnimation(count, for: self)
    }
    
    public func `repeat`() -> AnimationProviderProtocol {
        RepeatAnimation(nil, for: self)
    }
    
    public func autoreverse() -> AnimationProviderProtocol {
        Autoreverse(self)
    }
    
    public func delay(_ value: TimeInterval) -> AnimationProviderProtocol {
        Sequential {
            Interval(value)
            self
        }
    }
    
    public func delay(relative value: TimeInterval) -> AnimationProviderProtocol {
        Sequential {
            Interval(relative: value)
            self
        }
    }
    
}

private func curve(_ lhs: BezierCurve?, _ rhs: BezierCurve?) -> BezierCurve? {
    guard let l = lhs, let r = rhs else {
        return lhs ?? rhs
    }
    print(l, r, BezierCurve.between(l, r))
    return BezierCurve.between(l, r)
}
