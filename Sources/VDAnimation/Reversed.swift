//
//  Reversed.swift
//  VDTransition
//
//  Created by Данил Войдилов on 24.03.2021.
//

import Foundation

struct ReversedAnimation: VDAnimationProtocol {
	
	let animation: VDAnimationProtocol
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(inner: animation.delegate(with: options))
	}
	
	struct Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { inner.isRunning }
		var options: AnimationOptions { inner.options }
		var isInstant: Bool { inner.isInstant }
		var position: AnimationPosition {
			get {
				switch inner.position {
				case .end:		return .start
				case .start: 	return .end
				case .progress(let progress):
					return .progress(1 - progress)
				}
			}
			nonmutating set {
				switch newValue {
				case .end:		inner.position = .start
				case .start:	inner.position = .end
				case .progress(let progress):
					inner.position = .progress(1 - progress)
				}
			}
		}
		let inner: AnimationDelegateProtocol
		
		func play(with options: AnimationOptions) {
			var options = options
			options.isReversed = !(options.isReversed ?? false)
			inner.position = options.isReversed == true ? .end : .start
			inner.play(with: options)
		}
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
			switch position {
			case .none:
				inner.stop(at: .current)
			case .start:
				inner.stop(at: .end)
			case .end:
				inner.stop(at: .start)
			case .progress(let progress):
				inner.stop(at: .progress(1 - progress))
			}
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			inner.add(completion: completion)
		}
		
		func cancel() {
			inner.cancel()
		}
	}
}
