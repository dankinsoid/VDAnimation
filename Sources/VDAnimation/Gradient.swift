import SwiftUI

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

@available(iOS 13.0, *)
extension Gradient where Bound: VectorArithmetic {
    
	public func at(_ percent: Double) -> Bound {
		var result = from
		var dif = (to - from)
		dif.scale(by: percent)
		result = result + dif
		return result
	}
}

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
