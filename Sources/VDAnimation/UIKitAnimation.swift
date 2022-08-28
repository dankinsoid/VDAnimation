import UIKit

///UIKit animation
public struct UIViewAnimate: VDAnimationProtocol {
	
	let block: () -> Void
	let springTiming: UISpringTimingParameters?
	
	public init(_ block: @escaping () -> Void, spring: UISpringTimingParameters?) {
		self.block = block
		springTiming = spring
	}
	
	public init(_ closure: @escaping () -> Void) {
		block = closure
		springTiming = nil
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		let provider = VDTimingProvider(bezier: options.curve, spring: springTiming)
		let duration = options.duration?.absolute ?? 0
		let animator = VDViewAnimator(duration: duration, timingParameters: provider)
		animator.animationOptions = options
		animator.addAnimations(block)
		
		animator.pausesOnCompletion = !(options.complete ?? true)
		if options.isReversed == true {
			animator.isReversed = true
		}
		return animator
	}
}
