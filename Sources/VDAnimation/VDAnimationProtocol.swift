//
//  AnimationProtocol.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public protocol VDAnimationProtocol {
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol
}

extension VDAnimationProtocol {
	public func delegate() -> AnimationDelegateProtocol {
		delegate(with: .empty)
	}
}

public protocol ClosureAnimation: VDAnimationProtocol {
	init(_ closure: @escaping () -> Void)
}

extension VDAnimationProtocol {
	public var options: AnimationOptions { modified.options }
	public var modified: ModifiedAnimation { ModifiedAnimation(options: .empty, animation: self) }
	var chain: ValueChaining<Self> { ValueChaining(self) }
	
	@discardableResult
	public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegateProtocol {
		let result = delegate(with: options)
		let owner = Owner<AnimationDelegateProtocol>()
		owner.delegate = result
		result.add {
			completion($0)
			owner.delegate = nil
		}
		result.play()
		return result
	}
	
	@discardableResult
	public func start(_ completion: @escaping (Bool) -> Void) -> AnimationDelegateProtocol {
		start(with: .empty, { completion($0) })
	}
	
	@discardableResult
	public func start(_ completion: (() -> Void)? = nil) -> AnimationDelegateProtocol {
		start(with: .empty, { _ in completion?() })
	}
}

//extension AnimationDelegateProtocol {
//
//	public func set<F: BinaryFloatingPoint>(_ progress: F) {
//		self.progress = Double(progress)
////		set(position: .progress(Double(progress)), for: .empty, execute: true)
//	}
//
//	public func set(position: AnimationPosition) {
//		set(position: position, for: .empty, execute: true)
//	}
//}

extension Optional: VDAnimationProtocol where Wrapped: VDAnimationProtocol {
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		self?.delegate(with: options) ?? EmptyAnimationDelegate()
	}
}

public final class EmptyAnimationDelegate: AnimationDelegateProtocol {
	public var isInstant: Bool { true }
	public var options: AnimationOptions = .empty
	public var isRunning: Bool { false }
	public var position: AnimationPosition = .start
	private var completions: [(Bool) -> Void] = []
	public var infinity = false
	
	public func play(with options: AnimationOptions) {
		self.options = options.or(self.options)
		stop(at: .end)
	}
	public func pause() {}
	public func stop(at position: AnimationPosition?) {
		self.position = position ?? .end
		guard !infinity else { return }
		completions.forEach {
			$0(position == .end)
		}
	}
	public func add(completion: @escaping (Bool) -> Void) {
		completions.append(completion)
	}
}

final class Owner<T> {
	var delegate: T?
}
