//
//  Operators.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension AnimationProviderProtocol {
    
    public func duration(_ value: TimeInterval) -> AnimationModifier {
        asModifier.chain.modificators.duration[.absolute(value)]
    }
    
    public func duration(relative value: Double) -> AnimationModifier {
        asModifier.chain.modificators.duration[.relative(value)]
    }
    
    public func curve(_ value: BezierCurve) -> AnimationModifier {
        asModifier.chain.modificators.curve[value]
//        let result = asModifier
//        return result.chain.modificators.curve[CA.curve(value, result.modificators.curve)]
    }
    
    public func `repeat`(_ count: Int) -> AnimationModifier {
        RepeatAnimation(count, for: self).asModifier
    }
    
    public func `repeat`() -> AnimationModifier {
        RepeatAnimation(nil, for: self).asModifier
    }
    
    public func autoreverse() -> Autoreverse<Self> {
        Autoreverse(self)
    }
    
}

private func curve(_ lhs: BezierCurve?, _ rhs: BezierCurve?) -> BezierCurve? {
    guard let l = lhs, let r = rhs else {
        return lhs ?? rhs
    }
    print(l, r, BezierCurve.between(l, r))
    return BezierCurve.between(l, r)
}
