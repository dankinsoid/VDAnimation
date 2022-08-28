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
				switch inner.position {
				case .end:		return .start
				case .start: 	return .end
				case .progress(let progress):
					return .progress(1 - progress)
				}
			}
			set {
				firstStart = false
				switch newValue {
				case .end:		inner.position = .start
				case .start:	inner.position = .end
				case .progress(let progress):
					inner.position = .progress(1 - progress)
				}
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
	}
}

private extension AnimationOptions {
	
	var reversed: AnimationOptions {
		var result = self
		result.isReversed = !(result.isReversed ?? false)
		return result
	}
}
