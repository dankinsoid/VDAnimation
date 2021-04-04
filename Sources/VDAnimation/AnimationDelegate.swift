//
//  AnimationDelegate.swift
//  CA
//
//  Created by Daniil on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public protocol AnimationDelegateProtocol {
	var isRunning: Bool { get }
	var position: AnimationPosition { get nonmutating set }
	var options: AnimationOptions { get }
	var isInstant: Bool { get }
//	var animationState: AnimationState { get }
	
	func play(with options: AnimationOptions)
	func pause()
	func stop(at position: AnimationPosition?)
	func add(completion: @escaping (Bool) -> Void)
}

public protocol AnimationDelegateWrapper: AnimationDelegateProtocol {
	var inner: AnimationDelegateProtocol { get }
}

extension AnimationDelegateWrapper {
	public var isRunning: Bool { inner.isRunning }
	public var position: AnimationPosition { get { inner.position } nonmutating set { inner.position = newValue } }
	public var options: AnimationOptions { inner.options }
	public var isInstant: Bool { inner.isInstant }
	
	public func pause() { inner.pause() }
	public func stop(at position: AnimationPosition?) { inner.stop(at: position) }
	public func add(completion: @escaping (Bool) -> Void) { inner.add(completion: completion) }
}

public enum AnimationState: Equatable {
	case inactive, running, paused, stopped
}

extension AnimationDelegateProtocol {
	public func stop() {
		stop(at: .current)
	}
	public func play() { play(with: .empty) }
	public func pause(at position: AnimationPosition) {
		pause()
		self.position = position
	}
	public var progress: Double {
		get { position.complete }
		nonmutating set { position = .progress(newValue) }
	}
	
	func set(position: AnimationPosition?, stop: Bool) {
		if stop {
			self.stop(at: position)
		} else if let position = position {
			self.position = position
		}
	}
}
