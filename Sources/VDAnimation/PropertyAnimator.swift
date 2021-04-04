//
//  PropertyAnimator.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

@dynamicMemberLookup
public struct PropertyAnimator<Base, A: ClosureAnimation>: VDAnimationProtocol {
	let animatable: PropertyAnimatable
	private let get: () -> Base?
	
	init(_ animatable: PropertyAnimatable, get: @escaping () -> Base?) {
		self.animatable = animatable
		self.get = get
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegete(animatable, options: options)
	}
	
	public func instant() -> Instant {
		Instant({ self.animatable.setState(.end) }, onReverse: { self.animatable.setState(.start) })
	}
	
	public subscript<A>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, A>) -> AnimatePropertyMapper<Base, A> {
		AnimatePropertyMapper(object: get, animatable: animatable, keyPath: keyPath)
	}
	
	final class Delegete: AnimationDelegateProtocol {
		var isRunning: Bool { inner.isRunning }
		var position: AnimationPosition {
			get { inner.position }
			set { set(position: newValue) }
		}
		var options: AnimationOptions { inner.options }
		var isInstant: Bool { inner.isInstant }
		let animatable: PropertyAnimatable
		private var inner: AnimationDelegateProtocol
		
		init(_ animatable: PropertyAnimatable, options: AnimationOptions) {
			self.animatable = animatable
			self.inner = A.init { animatable.setState(.end) }.delegate(with: options)
		}
		
		func play(with options: AnimationOptions) {
			inner.play(with: options)
		}
		
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
			inner.stop(at: position)
		}
		
		public func set(position: AnimationPosition) {
			inner.position = position
//			animatable.setState(position)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			inner.add(completion: completion)
		}
	}
}

final class PropertyAnimatable {
	var updateInitial: () -> Void
	var setState: (AnimationPosition) -> Void
	
	static let empty = PropertyAnimatable(update: {}, set: {_ in})
	
	init(update: @escaping () -> Void, set: @escaping (AnimationPosition) -> Void) {
		updateInitial = update
		setState = set
	}
	
	func union(_ other: PropertyAnimatable) -> PropertyAnimatable {
		PropertyAnimatable(
			update: {
				self.updateInitial()
				other.updateInitial()
			},
			set: {
				self.setState($0)
				other.setState($0)
			}
		)
	}
}

final class PropertyOwner<T> {
	private var initial: T?
	private let value: T
	private let scale: (T, Double, T) -> T
	private let setter: (T?) -> Void
	private let getter: () -> T?
	
	var asAnimatable: PropertyAnimatable {
		PropertyAnimatable(update: updateInitial, set: set)
	}
	
	init(from initial: T?, getter: @escaping () -> T?, setter: @escaping (T?) -> Void, scale: @escaping (T, Double, T) -> T, value: T) {
		self.scale = scale
		self.setter = setter
		self.initial = initial
		self.getter = getter
		self.value = value
	}
	
	func updateInitial() {
		if initial == nil { initial = getter() }
	}
	
	func set(position: AnimationPosition) {
		switch position {
		case .start:
			setter(initial)
		case .progress(let k):
			updateInitial()
			setter(scale(initial ?? value, k, value))
		case .end:
			setter(value)
		}
	}
}
