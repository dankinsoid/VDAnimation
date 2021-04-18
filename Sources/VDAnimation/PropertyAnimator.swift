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
	var wrappedValue: W? { get set }
	var setInitial: (W) -> W { get set }
}

@dynamicMemberLookup
public struct UIKitChainingAnimation<W: AnyObject>: UIKitChainingType, VDAnimationProtocol {
	public private(set) var action: (W) -> W = { $0 }
	public weak var wrappedValue: W?
	public var setInitial: (W) -> W
	
	public init(_ wrappedValue: W?, setInitial: @escaping (W) -> W) {
		self.wrappedValue = wrappedValue
		self.setInitial = setInitial
	}
	
	public subscript<A>(dynamicMember keyPath: KeyPath<W, A>) -> ChainingProperty<Self, A> {
		ChainingProperty<Self, A>(self, getter: keyPath)
	}
	
	public func copy(with action: @escaping (W) -> W) -> UIKitChainingAnimation<W> {
		var result = UIKitChainingAnimation(wrappedValue, setInitial: setInitial)
		result.action = action
		return result
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegete(apply: { _ = self.wrappedValue.map(self.action) }, setInitial: { _ = self.wrappedValue.map(self.setInitial) }, options: options)
	}
	
	final class Delegete: AnimationDelegateProtocol {
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
			self.inner = UIKitAnimation(apply).delegate(with: options)
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
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ChainingProperty where C: UIKitChainingType {
	
	public subscript(_ value: B) -> C {
		self.get(from: nil, to: value)
	}
	
	public subscript(_ gradient: Gradient<B>) -> C {
		self.get(from: gradient.from, to: gradient.to)
	}
	
	private func get(from: B?, to value: B) -> C {
		guard let kp = getter as? WritableKeyPath<C.W, B> else { return chaining }
		let current = chaining.setInitial
		var result = chaining.copy {
			var wrapped = $0
			wrapped[keyPath: kp] = value
			return wrapped
		}
		let property = LazyProperty<B?> { from ?? result.wrappedValue?[keyPath: kp] }
		result.setInitial = {
			guard let new = property.wrappedValue else { return $0 }
			var wrapped = current($0)
			wrapped[keyPath: kp] = new
			return wrapped
		}
		return result
	}
}
