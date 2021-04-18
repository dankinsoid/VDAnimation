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
public func =~<V: Animatable>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	lhs.change(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: VectorArithmetic>(_ lhs: Binding<V>, _ rhs: V) -> StateChanges {
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
public func =~<V>(_ lhs: Binding<V>, _ rhs: V) -> StateChanges {
	let property = LazyProperty<V> { lhs.wrappedValue }
	return StateChanges {
		lhs.wrappedValue = $0 > 0.5 ? rhs : property.wrappedValue
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Animatable {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		SwiftUIAnimate(store, self.change(gradient))
	}
	
	public func to(_ value: Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value).at($0)
		}
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges { wrappedValue = gradient.at($0) }
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: VectorArithmetic {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		SwiftUIAnimate(store, self.change(gradient))
	}
	
	public func animate(_ store: AnimationsStore, to value: Value) -> VDAnimationProtocol {
		SwiftUIAnimate(store, self.to(value))
	}
	
	public func to(_ value: Value) -> StateChanges {
		let property = LazyProperty<Value> { self.wrappedValue }
		return StateChanges {
			wrappedValue = (property.wrappedValue...value).vectorAt($0)
		}
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges { wrappedValue = gradient.vectorAt($0) }
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding {
	
	public func map<T>(get: @escaping (Value) -> T, set: @escaping (Value, T) -> Value) -> Binding<T> {
		Binding<T>(
			get: { get(self.wrappedValue) },
			set: { self.wrappedValue = set(self.wrappedValue, $0) }
		)
	}
	
	public func map<T>(_ keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
		self[dynamicMember: keyPath]
	}
	
	public mutating func observe(_ observer: @escaping (_ old: Value, _ new: Value) -> Void) {
		let current = self
		self = Binding(
			get: { current.wrappedValue },
			set: {
				let old = current.wrappedValue
				current.wrappedValue = $0
				observer(old, $0)
			}
		)
	}
	
	public func didSet(_ action: @escaping (_ old: Value, _ new: Value) -> Void) -> Binding {
		Binding(
			get: { self.wrappedValue },
			set: {
				let old = self.wrappedValue
				self.wrappedValue = $0
				action(old, $0)
			}
		)
	}
	
	public func willSet(_ action: @escaping (_ old: Value, _ new: Value) -> Void) -> Binding {
		Binding(
			get: { self.wrappedValue },
			set: {
				action(self.wrappedValue, $0)
				self.wrappedValue = $0
			}
		)
	}
	
	public func didSet(_ action: @escaping (_ new: Value) -> Void) -> Binding {
		didSet { _, new in
			action(new)
		}
	}
	
	public func willSet(_ action: @escaping (_ new: Value) -> Void) -> Binding {
		willSet { _, new in
			action(new)
		}
	}
	
	public static func `var`(_ initial: Value) -> Binding {
		let wrapper = Wrapper(initial)
		return Binding(
			get: { wrapper.value },
			set: { wrapper.value = $0 }
		)
	}
	
	public static func `let`(_ value: Value) -> Binding {
		Binding(
			get: { value },
			set: { _ in }
		)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Equatable {
	
	public func skipEqual() -> Binding {
		Binding(
			get: { self.wrappedValue },
			set: {
				guard self.wrappedValue != $0 else { return }
				self.wrappedValue = $0
			}
		)
	}
}

private final class Wrapper<T> {
	var value: T
	init(_ value: T) { self.value = value }
}
