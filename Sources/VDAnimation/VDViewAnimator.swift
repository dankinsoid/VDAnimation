import UIKit

open class VDViewAnimator: UIViewPropertyAnimator, AnimationDelegateProtocol {
    
	open var position: AnimationPosition {
		get { .progress(Double(isReversed ? 1 - fractionComplete : fractionComplete)) }
		set {
			fractionComplete = CGFloat(isReversed ? 1 - newValue.complete : newValue.complete)
		}
	}
	private var completions: [(UIViewAnimatingPosition) -> Void] = []
	private var didSetOptions = false
	public var isInstant: Bool { false }
	private var wasCompleted = false
	var animationOptions: AnimationOptions = .empty
	public var options: AnimationOptions {
		animationOptions.or(AnimationOptions(curve: timingParameters?.bezier, complete: !pausesOnCompletion, isReversed: isReversed))
	}
	
	deinit {
		finishAnimation(at: .current)
	}
	
	override open func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
		guard state != .inactive else { return }
		if state != .stopped {
			stopAnimation(false)
		}
		if state == .stopped {
			super.finishAnimation(at: finalPosition)
		} else if let value = finalPosition.complete {
			fractionComplete = value
		}
	}
	
	override open func stopAnimation(_ withoutFinishing: Bool) {
		if !withoutFinishing {
			guard state != .stopped else {
				return
			}
			super.stopAnimation(withoutFinishing)
		} else {
			finishAnimation(at: .current)
		}
	}
	
	override open func pauseAnimation() {
		let prevRunning = isRunning
		super.pauseAnimation()
		if prevRunning, fractionComplete >= 0.99, pausesOnCompletion {
			wasCompleted = true
			self.completions.forEach {
				$0(.end)
			}
		} 
	}
	
	override open func startAnimation() {
		prepareStart()
		if animationOptions.duration?.absolute == 0 {
			zeroAnimation()
			return
		}
		super.startAnimation()
	}
	
	override open func continueAnimation(withTimingParameters parameters: UITimingCurveProvider?, durationFactor: CGFloat) {
		prepareStart()
		if durationFactor == 0 {
			zeroAnimation()
			return
		}
		super.continueAnimation(withTimingParameters: parameters, durationFactor: durationFactor)
	}
	
	private func prepareStart() {
		wasCompleted = false
		if isReversed, fractionComplete == 0 {
			fractionComplete = 0.01
		}
	}
	
	private func zeroAnimation() {
		if pausesOnCompletion {
			fractionComplete = 1
			pauseAnimation()
		} else {
			finishAnimation(at: isReversed ? .start : .end)
		}
	}
	
	override open func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
		completions.append(completion)
		super.addCompletion {[weak self] in
			guard self?.wasCompleted == false else { return }
			completion(self?.isReversed == true ? $0.reversed : $0)
		}
	}
	
	public func add(completion: @escaping (Bool) -> Void) {
		addCompletion {
			completion($0 == .end)
		}
	}
	
	open func play(with options: AnimationOptions) {
		animationOptions = options.or(animationOptions)
		let factor = self.factor(for: options)
		isReversed = animationOptions.isReversed ?? isReversed
		pausesOnCompletion = animationOptions.complete.map { !$0 } ?? pausesOnCompletion
		let timing = options.curve.map { VDTimingProvider(bezier: $0, spring: nil) }
		let noOptions = (timing == nil || timing?.isEqual(to: timingParameters) == true) && factor == 1
		if !didSetOptions && noOptions {
			startAnimation()
		} else {
			didSetOptions = !noOptions
			super.startAnimation()
			super.pauseAnimation()
			continueAnimation(withTimingParameters: timing, durationFactor: factor)
		}
	}
	
	private func factor(for options: AnimationOptions) -> CGFloat {
		switch options.duration ?? animationOptions.duration {
		case .none:
			return 1
		case .absolute(let time):
			return duration == 0 ? 0 : CGFloat(time / duration)
		case .relative(let value):
			return CGFloat(value)
		}
	}
	
	open func pause() {
		pauseAnimation()
	}
	
	open func stop(at position: AnimationPosition?) {
		switch position {
        case .some(.start):
			finishAnimation(at: .start)
        case .some(.end):
			finishAnimation(at: .end)
        case .some(let position):
            pauseAnimation()
            self.fractionComplete = CGFloat(position.complete)
            finishAnimation(at: .current)
        case .none:
            finishAnimation(at: .current)
		}
	}
}

extension UITimingCurveProvider {
	
	public var bezier: BezierCurve? {
		cubicTimingParameters.map { BezierCurve($0.controlPoint1, $0.controlPoint2) }
	}
	
	public func isEqual(to rhs: UITimingCurveProvider?) -> Bool {
		cubicTimingParameters == rhs?.cubicTimingParameters && timingCurveType == rhs?.timingCurveType  && springTimingParameters == rhs?.springTimingParameters
	}
}

extension UIViewAnimatingState {
    
	var string: String {
		switch self {
		case .active: return "active"
		case .inactive: return "inactive"
		case .stopped: return "stopped"
		@unknown default: return String(describing: self)
		}
	}
}

extension UIViewAnimatingPosition {
    
	public var reversed: UIViewAnimatingPosition {
		switch self {
		case .end:		return .start
		case .start:	return .end
		default:			return self
		}
	}
	
	public var complete: CGFloat? {
		switch self {
		case .end:		return 1
		case .start:	return 0
		default:			return nil
		}
	}
}
