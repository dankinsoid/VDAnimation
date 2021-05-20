//
//  BindingOperators.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import Foundation
import SwiftUI

infix operator =~: AssignmentPrecedence

public struct StateChanges {
	public let change: (Double) -> Void
	
	public var reversed: StateChanges {
		StateChanges { self.change(1 - $0) }
	}
	
	public static var identity: StateChanges { StateChanges {_ in} }
	
	public init(_ change: @escaping (Double) -> Void) {
		self.change = change
	}
	
	public func combined(with changes: StateChanges) -> StateChanges {
		StateChanges { self.change($0); changes.change($0) }
	}
	
	public mutating func combine(with changes: StateChanges) {
		self = combined(with: changes)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: Animatable>(_ lhs: Binding<V>, _ rhs: V) -> StateChanges {
	lhs.to(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: Animatable>(_ lhs: Binding<V>, _ rhs: @escaping (V) -> V) -> StateChanges {
	lhs.to(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: Animatable>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	lhs.change(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: VectorArithmetic>(_ lhs: Binding<V>, _ rhs: V) -> StateChanges {
	lhs.to(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: VectorArithmetic>(_ lhs: Binding<V>, _ rhs: @escaping (V) -> V) -> StateChanges {
	lhs.to(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: VectorArithmetic>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	lhs.change(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	StateChanges {
		lhs.wrappedValue = $0 > 0.5 ? rhs.to : rhs.from
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V>(_ lhs: Binding<V>, _ rhs: @escaping (V) -> V) -> StateChanges {
	let property = LazyProperty<V> { lhs.wrappedValue }
	return StateChanges {
		lhs.wrappedValue = $0 > 0.5 ? rhs(lhs.wrappedValue) : property.wrappedValue
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V>(_ lhs: Binding<V>, _ rhs: V) -> StateChanges {
	let property = LazyProperty<V> { lhs.wrappedValue }
	return StateChanges {
		lhs.wrappedValue = $0 > 0.5 ? rhs : property.wrappedValue
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Animatable {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		Animate(store, self.change(gradient))
	}
	
	public func to(_ value: Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value).at($0)
		}
	}
	
	public func to(_ value: @escaping (Value) -> Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value(wrappedValue)).at($0)
		}
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges { wrappedValue = gradient.at($0) }
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: VectorArithmetic {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		Animate(store, self.change(gradient))
	}
	
	public func animate(_ store: AnimationsStore, to value: Value) -> VDAnimationProtocol {
		Animate(store, self.to(value))
	}
	
	public func to(_ value: Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value).at($0)
		}
	}
	
	public func to(_ value: @escaping (Value) -> Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value(wrappedValue)).at($0)
		}
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges { wrappedValue = gradient.at($0) }
	}
}
