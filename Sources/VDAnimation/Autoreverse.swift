import Foundation

struct Autoreverse<Animation: VDAnimationProtocol>: VDAnimationProtocol {
	
	private let animation: Animation
	
	init(_ animation: Animation) {
		self.animation = animation
	}
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		let option = AnimationOptions(duration: self.duration(from: options.duration), complete: false, isReversed: false)
		let delegate = animation.delegate(with: option)
		let duration = self.fullDuration(from: delegate.options.duration)
		return Delegate(inner: delegate, options: options.set(.duration(duration)))
	}
	
	private func duration(from dur: AnimationDuration?) -> AnimationDuration? {
		guard let duration = dur else { return nil }
		switch duration {
		case .absolute(let time):   return .absolute(time / 2)
		case .relative(let time):   return .relative(time)
		}
	}
	
	private func fullDuration(from dur: AnimationDuration?) -> AnimationDuration? {
		guard let duration = dur else { return nil }
		switch duration {
		case .absolute(let time):   return .absolute(time * 2)
		case .relative(let time):   return .relative(time)
		}
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isInstant: Bool { inner.isInstant }
		var isRunning: Bool { inner.isRunning }
		var position: AnimationPosition {
			get {
				switch inner.position {
				case .start:
					return step == .forward ? .start : .end
				case .end:
					return .progress(0.5)
                default:
                    switch step {
                    case .forward: return .progress(inner.position.complete / 2)
                    case .back: return .progress(1 - inner.position.complete / 2)
                    }
				}
			}
			set {
				let (newStep, newPosition) = targetPosition(for: newValue)
				step = newStep
				inner.position = newPosition
			}
		}
		private var inner: AnimationDelegateProtocol
		private var step: AutoreverseStep = .forward
		private var completions: [(Bool) -> Void] = []
		private var count = 0
		private var isStopped = false
		var options: AnimationOptions
		
		init(inner: AnimationDelegateProtocol, options: AnimationOptions) {
			self.inner = inner
			self.options = options
			prepare()
		}
		
		private func prepare() {
			inner.add {[weak self] in
				self?.innerComplete($0)
			}
		}
		
		func play(with options: AnimationOptions) {
			self.options = options.or(self.options)
			isStopped = false
			inner.play(with: getOptions())
		}
		
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
			isStopped = true
			guard let position = position else {
				inner.stop(at: nil)
				return
			}
			let (newStep, newPosition) = targetPosition(for: position)
			step = newStep
			inner.stop(at: newPosition)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		private func innerComplete(_ completed: Bool) {
			step = step.inverted
			count += 1
			if count == 1 {
				if !isStopped {
					inner.play(with: getOptions())
				}
			} else {
				completions.forEach { $0(completed) }
				count = 0
			}
		}
		
		private func targetPosition(for position: AnimationPosition) -> (AutoreverseStep, AnimationPosition) {
			switch position {
			case .start:
				return (.forward, .start)
			case .end:
				return (.back, .start)
			default:
                switch position.complete {
				case 0..<0.5:
					return (.forward, .progress(2 * position.complete))
				default:
					return (.back, .progress((1 - position.complete) * 2))
				}
			}
		}
		
		private func getOptions() -> AnimationOptions {
			var result = options
			let step = (options.isReversed == true) ? self.step.inverted : self.step
			result.isReversed = step == .back
			result.complete = options.complete != false && step == .back
			setCurve(for: &result, step: step)
			return result
		}
		
		private func setCurve(for options: inout AnimationOptions, step: AutoreverseStep) {
			guard let duration = options.duration else { return }
			guard let fullCurve = options.curve, fullCurve != .linear else {
                options.duration = duration / 2.0
				return
			}
			let progress = step == .forward ? 0...0.5 : 0.5...1
			var (curve1, newDuration) = fullCurve.split(range: progress)
			if let curve2 = inner.options.curve {
				curve1 = BezierCurve.between(curve1, curve2)
			}
			options.duration = duration * newDuration
			options.curve = curve1
		}
	}
}
