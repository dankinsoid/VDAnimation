//
//  Foundation++.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension Sequence {
    
    func reduce<Result>(while condition: (Result) -> Bool, _ initialValue: Result, _ reducing: (Result, Element) -> Result) -> Result {
        var result = initialValue
        for element in self {
            guard condition(result) else { return result }
            result = reducing(result, element)
        }
        return result
    }
    
}

public struct Gradient<Bound> {
    public var from: Bound
    public var to: Bound
}

public func ...<Bound>(_ lhs: Bound, _ rhs: Bound) -> Gradient<Bound> {
    Gradient(from: lhs, to: rhs)
}

extension Gradient where Bound: ScalableConvertable {
    public func at(_ percent: Double) -> Bound {
        Bound(scaleData: from.scaleData + (to.scaleData - from.scaleData).scaled(by: percent))
    }
}
