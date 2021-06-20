//
//  Animation++.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import SwiftUI
import VDKit

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Animation {
	
	public static func bezier(_ bezier: BezierCurve, duration: Double = 0.35) -> Animation {
		.timingCurve(Double(bezier.point1.x), Double(bezier.point1.y), Double(bezier.point2.x), Double(bezier.point2.y), duration: duration)
	}
	
	public static func with(options: AnimationOptions) -> Animation {
		.bezier(options.curve ?? .linear, duration: options.duration?.absolute ?? 0.35)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: VectorArithmetic {
	
	public func ca(_ store: AnimationsStore) -> ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ca(store: store)
	}
	
	public var ca: ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ca(store: nil)
	}
	
	private func ca(store: AnimationsStore?) -> ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ChainProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: self), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Animatable {
	
	public func ca(_ store: AnimationsStore) -> ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ca(store: store)
	}
	
	public var ca: ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ca(store: nil)
	}
	
	private func ca(store: AnimationsStore?) -> ChainProperty<SwiftUIChainingAnimation<Value>, Value> {
		ChainProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: self), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
	
	public func ca(_ store: AnimationsStore) -> ChainProperty<SwiftUIChainingAnimation<Self>, Self> {
		ca(store: store)
	}
	
	public var ca: ChainProperty<SwiftUIChainingAnimation<Self>, Self> {
		ca(store: nil)
	}
	
	private func ca(store: AnimationsStore?) -> ChainProperty<SwiftUIChainingAnimation<Self>, Self> {
		ChainProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: .var(self)), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol SwiftUIChainingType: Chaining {
	var binding: Binding<Value> { get }
	var changes: StateChanges { get set }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
@dynamicMemberLookup
public struct SwiftUIChainingAnimation<Value>: SwiftUIChainingType, VDAnimationProtocol {
	
	let store: AnimationsStore?
	public var changes: StateChanges
	public var binding: Binding<Value>
	public var apply: (Value) -> Value = { $0 }
	
	public init(store: AnimationsStore?, changes: StateChanges, binding: Binding<Value>) {
		self.store = store
		self.changes = changes
		self.binding = binding
	}
	
	public subscript<A>(dynamicMember keyPath: KeyPath<Value, A>) -> ChainProperty<Self, A> {
		ChainProperty<Self, A>(self, getter: keyPath)
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Animate(store, changes).delegate(with: options)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainProperty where Base: SwiftUIChainingType, Value: VectorArithmetic {
	
	public func callAsFunction(_ input: Value) -> Base {
		self[input]
	}
	
	public subscript(_ value: Value) -> Base {
		var result = chaining
		if let kp = getter as? WritableKeyPath<Base.Value, Value> {
			result.changes.combine(with: result.binding.map(kp).to(value))
		}
		return result
	}
	
	public func callAsFunction(_ input: Gradient<Value>) -> Base {
		self[input]
	}
	
	public subscript(_ gradient: Gradient<Value>) -> Base {
		var result = chaining
		if let kp = getter as? WritableKeyPath<Base.Value, Value> {
			result.changes.combine(with: result.binding.map(kp).change(gradient))
		}
		return result
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainProperty where Base: SwiftUIChainingType, Value: Animatable {
	
	public func callAsFunction(_ input: Value) -> Base {
		self[input]
	}
	
	public subscript(_ value: Value) -> Base {
		var result = chaining
		if let kp = getter as? WritableKeyPath<Base.Value, Value> {
			result.changes.combine(with: result.binding.map(kp).to(value))
		}
		return result
	}
	
	public func callAsFunction(_ input: Gradient<Value>) -> Base {
		self[input]
	}
	
	public subscript(_ gradient: Gradient<Value>) -> Base {
		var result = chaining
		if let kp = getter as? WritableKeyPath<Base.Value, Value> {
			result.changes.combine(with: result.binding.map(kp).change(gradient))
		}
		return result
	}
}
