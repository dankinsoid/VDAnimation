//
//  Instant.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit

@available(*, deprecated, message: "Renamed to 'Instant'")
public typealias WithoutAnimation = Instant

public struct Instant: ClosureAnimation {
	
	public var modified: ModifiedAnimation {
		ModifiedAnimation(
			options: AnimationOptions.empty.chain.duration[.absolute(0)].isInstant[apply: true],
			animation: self
		)
	}
	
	private let block: () -> Void
	private let initial: (() -> Void)?
	private let usePerform: Bool
	
	public init(_ closure: @escaping () -> Void) {
		block = closure
		initial = nil
		usePerform = false
	}
	
	public init(withoutAnimation: Bool = false, _ closure: @escaping () -> Void, onReverse: @escaping () -> Void) {
		block = closure
		initial = onReverse
		usePerform = withoutAnimation
	}
	
	public init(withoutAnimation: Bool = false, _ closure: @escaping () -> Void) {
		block = closure
		initial = nil
		usePerform = withoutAnimation
	}
	
	@discardableResult
	public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
		let duration = options.duration?.absolute ?? 0
		let anim = options.isReversed ? (initial ?? block) : block
		if duration == 0 {
			execute(anim, completion)
			return .end
		} else {
			let remote = RemoteDelegate(completion)
			DispatchTimer.execute(seconds: duration) {
				guard !remote.isStopped else { return }
				self.execute(anim, completion)
			}
			return remote.delegate
		}
	}
	
	public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
		let end = options.isReversed ? position.reversed : position
		switch end.complete {
		case 1:     if execute { self.execute(block) {_ in } }
		default:    break
		}
	}
	
	private func execute(_ block: () -> Void, _ completion: @escaping (Bool) -> Void) {
		usePerform ? UIView.performWithoutAnimation(block) : block()
		completion(true)
	}
	
}

