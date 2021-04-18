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

public struct Instant: VDAnimationProtocol {
	
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
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(block, usePerform: usePerform)
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { false }
		private var completions: [(Bool) -> Void] = []
		let action: () -> Void
		let usePerform: Bool
		var isInstant: Bool { true }
		var options: AnimationOptions {
			AnimationOptions.empty.chain.duration[.absolute(0)].complete[true].apply()
		}
		var position: AnimationPosition = .start
		private var hasStopped = false
		
		init(_ action: @escaping () -> Void, usePerform: Bool) {
			self.usePerform = usePerform
			self.action = action
		}
		
		func play(with options: AnimationOptions) {
			stop(at: .end, final: false)
		}
		
		func pause() {}
		
		func stop(at position: AnimationPosition?) {
			stop(at: position, final: true)
		}
		
		func stop(at position: AnimationPosition?, final: Bool) {
			self.position = position ?? self.position
			guard !hasStopped else { return }
			hasStopped = final
			if self.position == .end, !final {
				usePerform ? UIView.performWithoutAnimation(action) : action()
			}
			self.completions.forEach {
				$0(self.position == .end)
			}
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
	}
}
