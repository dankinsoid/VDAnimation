//
//  AnimationDuration.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public enum RelationValue<Value> {
	case absolute(Value), relative(Value)
	
	public var absolute: Value? {
		if case .absolute(let value) = self { return value }
		return nil
	}
	
	public var relative: Value? {
		if case .relative(let value) = self { return value }
		return nil
	}
	
	public var type: RelationType {
		switch self {
		case .absolute: return .absolute
		case .relative: return .relative
		}
	}
	
	public var value: Value {
		get {
			switch self {
			case .absolute(let value): return value
			case .relative(let value): return value
			}
		}
		set {
			switch self {
			case .absolute: self = .absolute(newValue)
			case .relative: self = .relative(newValue)
			}
		}
	}
}

public enum RelationType: String, Hashable {
	case absolute, relative
}

extension RelationValue: Equatable where Value: Equatable {}
extension RelationValue: Hashable where Value: Hashable {}

public typealias AnimationDuration = RelationValue<TimeInterval>

public func /<F: BinaryFloatingPoint>(_ lhs: RelationValue<F>, _ rhs: F) -> RelationValue<F> {
    switch lhs {
    case .absolute(let value): return .absolute(value / rhs)
    case .relative(let value): return .relative(value / rhs)
    }
}

public func *<F: BinaryFloatingPoint>(_ lhs: RelationValue<F>, _ rhs: F) -> RelationValue<F> {
    switch lhs {
    case .absolute(let value): return .absolute(value * rhs)
    case .relative(let value): return .relative(value * rhs)
    }
}

public func *<F: BinaryFloatingPoint>(_ lhs: F, _ rhs: RelationValue<F>) -> RelationValue<F> {
    rhs * lhs
}
