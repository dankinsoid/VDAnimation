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
	
	public func ca(_ store: AnimationsStore) -> ChainingProperty<SwiftUIChainingAnimation<Value>, Value> {
		ChainingProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: self), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Animatable {
	
	public func ca(_ store: AnimationsStore) -> ChainingProperty<SwiftUIChainingAnimation<Value>, Value> {
		ChainingProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: self), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
	
	public func ca(_ store: AnimationsStore) -> ChainingProperty<SwiftUIChainingAnimation<Self>, Self> {
		ChainingProperty(SwiftUIChainingAnimation(store: store, changes: .identity, binding: .var(self)), getter: \.self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol SwiftUIChainingType: Chaining {
	var binding: Binding<W> { get }
	var changes: StateChanges { get set }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
@dynamicMemberLookup
public struct SwiftUIChainingAnimation<W>: SwiftUIChainingType, VDAnimationProtocol {
	
	public private(set) var action: (W) -> W = { $0 }
	let store: AnimationsStore
	public var changes: StateChanges
	public var binding: Binding<W>
	
	public init(store: AnimationsStore, changes: StateChanges, binding: Binding<W>) {
		self.store = store
		self.changes = changes
		self.binding = binding
	}
	
	public subscript<A>(dynamicMember keyPath: KeyPath<W, A>) -> ChainingProperty<Self, A> {
		ChainingProperty<Self, A>(self, getter: keyPath)
	}
	
	public func copy(with action: @escaping (W) -> W) -> SwiftUIChainingAnimation<W> {
		var result = SwiftUIChainingAnimation(store: store, changes: changes, binding: binding)
		result.action = action
		return result
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		SwiftUIAnimate(store, changes).delegate(with: options)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainingProperty where C: SwiftUIChainingType, B: VectorArithmetic {
	
	public subscript(_ value: B) -> C {
		var result = chaining
		if let kp = getter as? WritableKeyPath<C.W, B> {
			result.changes.combine(with: result.binding.map(kp).to(value))
		}
		return result
	}
	
	public subscript(_ gradient: Gradient<B>) -> C {
		var result = chaining
		if let kp = getter as? WritableKeyPath<C.W, B> {
			result.changes.combine(with: result.binding.map(kp).change(gradient))
		}
		return result
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainingProperty where C: SwiftUIChainingType, B: Animatable {

	public subscript(_ value: B) -> C {
		var result = chaining
		if let kp = getter as? WritableKeyPath<C.W, B> {
			result.changes.combine(with: result.binding.map(kp).to(value))
		}
		return result
	}
	
	public subscript(_ gradient: Gradient<B>) -> C {
		var result = chaining
		if let kp = getter as? WritableKeyPath<C.W, B> {
			result.changes.combine(with: result.binding.map(kp).change(gradient))
		}
		return result
	}
}
