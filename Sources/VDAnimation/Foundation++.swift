//
//  Foundation++.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import SwiftUI

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
    
    public init(_ from: Bound, _ to: Bound) {
        self.from = from
        self.to = to
    }
}

public func ...<Bound>(_ lhs: Bound, _ rhs: Bound) -> Gradient<Bound> {
    Gradient(lhs, rhs)
}

extension Gradient where Bound: ScalableConvertable {
    public func at(_ percent: Double) -> Bound {
        Bound(scaleData: from.scaleData + (to.scaleData - from.scaleData).scaled(by: percent))
    }
}

@available(iOS 13.0, *)
extension Gradient where Bound: Animatable {
	public func at(_ percent: Double) -> Bound {
		var result = from
		var dif = (to.animatableData - from.animatableData)
		dif.scale(by: percent)
		result.animatableData = result.animatableData + dif
		return result
	}
}

//extension Gradient where Bound: VectorArithmetic {
//	public func at(_ percent: Double) -> Bound {
//		var result = from
//		var dif = (to - from)
//		dif.scale(by: percent)
//		result = result + dif
//		return result
//	}
//}

extension Gradient: Equatable where Bound: Equatable {}
extension Gradient: Hashable where Bound: Hashable {}

extension Gradient: AdditiveArithmetic where Bound: AdditiveArithmetic {
    public static var zero: Gradient<Bound> { Gradient(.zero, .zero) }
    
    public static func +(lhs: Gradient<Bound>, rhs: Gradient<Bound>) -> Gradient<Bound> {
        Gradient(lhs.from + rhs.from, lhs.to + rhs.to)
    }
    
    public static func +(lhs: Bound, rhs: Gradient<Bound>) -> Gradient<Bound> {
        Gradient(lhs + rhs.from, lhs + rhs.to)
    }
    
    public static func +(lhs: Gradient<Bound>, rhs: Bound) -> Gradient<Bound> {
        Gradient(lhs.from + rhs, lhs.to + rhs)
    }
    
    public static func +=(lhs: inout Gradient<Bound>, rhs: Gradient<Bound>) {
        lhs = lhs + rhs
    }
    
    public static func +=(lhs: inout Gradient<Bound>, rhs: Bound) {
        lhs = lhs + rhs
    }
    
    public static func -(lhs: Gradient<Bound>, rhs: Gradient<Bound>) -> Gradient<Bound> {
        Gradient(lhs.from - rhs.from, lhs.to - rhs.to)
    }
    
    public static func -(lhs: Bound, rhs: Gradient<Bound>) -> Gradient<Bound> {
        Gradient(lhs - rhs.from, lhs - rhs.to)
    }
    
    public static func -(lhs: Gradient<Bound>, rhs: Bound) -> Gradient<Bound> {
        Gradient(lhs.from - rhs, lhs.to - rhs)
    }
    
    public static func -=(lhs: inout Gradient<Bound>, rhs: Gradient<Bound>) {
        lhs = lhs - rhs
    }
    
    public static func -=(lhs: inout Gradient<Bound>, rhs: Bound) {
        lhs = lhs - rhs
    }

}

//
//@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
//extension Gradient where Bound: Animatable {
//    public func at(_ percent: Double) -> Bound {
//        var result = from
//        result.animatableData = (from.animatableData...to.animatableData).at(percent)
//        return result
//    }
//}
//
//@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
//extension Gradient where Bound: VectorArithmetic {
//    public func at(_ percent: Double) -> Bound {
//        var result = to - from
//        result.scale(by: percent)
//        result += from
//        return result
//    }
//}
