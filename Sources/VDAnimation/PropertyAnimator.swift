//
//  PropertyAnimator.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit

public protocol UIKitChainingType: Chaining {
	mutating func onGetProperty<P>(_ keyPath: WritableKeyPath<Value, P>, _ value: P, from: P?)
}

@dynamicMemberLookup
public struct UIKitChainingAnimation<Value: AnyObject>: UIKitChainingType, VDAnimationProtocol {
	
	private weak var wrappedValue: Value?
	private var setInitial: (Value) -> Value
	public var apply: (inout Value) -> Void = { _ in }
	
	public init(_ wrappedValue: Value?, setInitial: @escaping (Value) -> Value) {
		self.wrappedValue = wrappedValue
		self.setInitial = setInitial
	}
	
	public subscript<A>(dynamicMember keyPath: KeyPath<Value, A>) -> ChainProperty<Self, A> {
		ChainProperty<Self, A>(self, getter: keyPath)
	}
	
	public mutating func onGetProperty<P>(_ keyPath: WritableKeyPath<Value, P>, _ value: P) {
		onGetProperty(keyPath, value, from: nil)
	}
	
	public mutating func onGetProperty<P>(_ keyPath: WritableKeyPath<Value, P>, _ value: P, from: P?) {
		let property = Lazy<P?> {[wrappedValue] in from ?? wrappedValue?[keyPath: keyPath] }
		setInitial = {[setInitial] in
			guard let new = property.wrappedValue else { return $0 }
			var wrapped = setInitial($0)
			wrapped[keyPath: keyPath] = new
			return wrapped
		}
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		UIKitChainingDelegete(
			apply: {
				if var value = self.wrappedValue {
					self.apply(&value)
				}
			},
			setInitial: { _ = self.wrappedValue.map(self.setInitial) },
			options: options
		)
	}
}

private final class UIKitChainingDelegete: AnimationDelegateProtocol {
	var isRunning: Bool { inner.isRunning }
	var position: AnimationPosition {
		get { inner.position }
		set { set(position: newValue) }
	}
	var options: AnimationOptions { inner.options }
	var isInstant: Bool { inner.isInstant }
	public var setInitial: () -> Void
	private var wasInited = false
	private var inner: AnimationDelegateProtocol
	
	init(apply: @escaping () -> Void, setInitial: @escaping () -> Void, options: AnimationOptions) {
		self.setInitial = setInitial
		self.inner = UIViewAnimate(apply).delegate(with: options)
	}
	
	func play(with options: AnimationOptions) {
		setInitialIfNeeded()
		inner.play(with: options)
	}
	
	func pause() {
		inner.pause()
	}
	
	func stop(at position: AnimationPosition?) {
		inner.stop(at: position)
	}
	
	public func set(position: AnimationPosition) {
		setInitialIfNeeded()
		inner.position = position
	}
	
	func add(completion: @escaping (Bool) -> Void) {
		inner.add(completion: completion)
	}
	
	private func setInitialIfNeeded() {
		guard !wasInited else { return }
		wasInited = true
		setInitial()
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainProperty where Base: UIKitChainingType {
	
	public func callAsFunction(_ input: Gradient<Value>) -> Base {
		self[input]
	}
	
	public subscript(_ gradient: Gradient<Value>) -> Base {
		guard let kp = getter as? WritableKeyPath<Base.Value, Value> else { return chaining }
		var result = chaining
		result.onGetProperty(kp, gradient.to, from: gradient.from)
		result.apply = self[gradient.to].apply
		return result
	}
}
