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
    
//    public func repeatCount(_ repeatCount: Int, autoreverses: Bool = true) -> AnimationModifier {
//        asModifier.chain.modificators.repeatCount[max(1, repeatCount)].chain.modificators.autoreverses[autoreverses]
//    }
//    
//    public func repeatForever(autoreverses: Bool) -> AnimationModifier {
//        asModifier.chain.modificators.repeatCount[.max].chain.modificators.autoreverses[autoreverses]
//    }
    
}
