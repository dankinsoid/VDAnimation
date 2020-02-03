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
    }
    
    public func `repeat`(_ count: Int) -> AnimationModifier {
        RepeatAnimation(count, for: self).asModifier
    }
    
    public func `repeat`() -> AnimationModifier {
        RepeatAnimation(nil, for: self).asModifier
    }
    
}
