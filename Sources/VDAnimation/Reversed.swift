import Foundation

struct ReversedAnimation: VDAnimationProtocol {
	
	let animation: VDAnimationProtocol
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(inner: animation.delegate(with: options.reversed))
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { inner.isRunning }
		var options: AnimationOptions { inner.options.reversed }
		var isInstant: Bool { inner.isInstant }
		var position: AnimationPosition {
			get {
                inner.position.reversed
			}
			set {
				firstStart = false
                inner.position = newValue.reversed
			}
		}
		let inner: AnimationDelegateProtocol
		private var firstStart = true
		
		init(inner: AnimationDelegateProtocol) {
			self.inner = inner
		}
		
		func play(with options: AnimationOptions) {
			let options = options.or(inner.options.reversed).reversed
			if firstStart {
				inner.position = options.isReversed == true ? .end : .start
				firstStart = false
			}
			inner.play(with: options)
		}
		
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
            inner.stop(at: position?.reversed)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			inner.add(completion: completion)
		}
	}
}

private extension AnimationOptions {
	
	var reversed: AnimationOptions {
		var result = self
		result.isReversed = !(result.isReversed ?? false)
		return result
	}
}
