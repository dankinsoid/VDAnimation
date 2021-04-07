//
//  DisappearAnimation.swift
//  VDTransition
//
//  Created by Данил Войдилов on 04.04.2021.
//

import Foundation

struct DisappearAnimation: VDAnimationProtocol {
	let animation: VDAnimationProtocol
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(animation.delegate(with: options.chain.complete[false].apply()), complete: options.complete ?? true)
	}
	
	final class Delegate: AnimationDelegateWrapper {
		let inner: AnimationDelegateProtocol
		private var completions: [(Bool) -> Void] = []
		private var complete: Bool
		private var wasStopped = false
		
		init(_ inner: AnimationDelegateProtocol, complete: Bool) {
			self.inner = inner
			self.complete = complete
		}
		
		func play(with options: AnimationOptions) {
			wasStopped = false
			complete = options.complete ?? complete
			inner.play(with: options.chain.complete[false].apply())
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
			inner.add {[weak self] in
				self?.completed($0)
			}
		}
		
		private func completed(_ completed: Bool) {
			guard !wasStopped else { return }
			if complete {
				wasStopped = true
				inner.stop(at: .start)
			} else {
				inner.position = .start
			}
			completions.forEach {
				$0(completed)
			}
		}
		
		func stop(at position: AnimationPosition?) {
			inner.stop(at: position?.complete == 1 ? .start : (position ?? .start))
		}
	}
}
