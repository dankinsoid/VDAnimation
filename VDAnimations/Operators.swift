//
//  Operators.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension VDAnimationProtocol {
    
    public func duration(_ value: TimeInterval) -> VDAnimationProtocol {
        modified.chain.options.duration[.absolute(value)]
    }
    
    public func duration(relative value: Double) -> VDAnimationProtocol {
        modified.chain.options.duration[.relative(value)]
    }
    
    public func curve(_ value: BezierCurve) -> VDAnimationProtocol {
        modified.chain.options.curve[value]
//        let result = modified
//        return result.chain.options.curve[CA.curve(value, result.options.curve)]
    }
    
    public func curve<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) -> VDAnimationProtocol {
        modified.chain.options.curve[.init(p1, p2)]
    }
    
    public func `repeat`(_ count: Int) -> VDAnimationProtocol {
        RepeatAnimation(count, for: self)
    }
    
    public func `repeat`() -> VDAnimationProtocol {
        RepeatAnimation(nil, for: self)
    }
    
    public func autoreverse() -> VDAnimationProtocol {
        Autoreverse(self)
    }
    
    public func delay(_ value: TimeInterval) -> VDAnimationProtocol {
        Sequential {
            Interval(value)
            self
        }
    }
    
    public func delay(relative value: TimeInterval) -> VDAnimationProtocol {
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
