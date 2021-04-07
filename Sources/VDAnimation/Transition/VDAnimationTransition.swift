//
//  VDAnimationTransition.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

open class VDAnimationTransition: UIPercentDrivenInteractiveTransition {
	
	public var completion: ((Bool) -> Void)?
	public weak var vc: UIViewController?
	public weak var present: UIViewController?
	public weak var delegate: VDTransitioningDelegate?
	public var transitioning: VDAnimatedTransitioning
	
	public init(transitioning: VDAnimatedTransitioning, delegate: VDTransitioningDelegate?) {
		self.transitioning = transitioning
		self.delegate = delegate
		super.init()
	}
	
	open func begin() {
		delegate?.isInteractive = true
		switch transitioning.transitionType {
		case .dismiss, .present:
			vc?.dismiss(animated: true, completion: nil)
		case .pop, .push:
			(vc as? UINavigationController)?.popViewController(animated: true)
		default:
			break
		}
	}
	
	override open func cancel() {
		super.cancel()
		transitioning.animator?.cancel()
		delegate?.isInteractive = false
		transitioning.animationCompleted(false)
		completion?(false)
	}
	
	override open func finish() {
		super.finish()
		transitioning.animator?.stop(at: .end)
		delegate?.isInteractive = false
		transitioning.animationCompleted(true)
		completion?(true)
	}
	
	open func complete(duration: Double?, finish: Bool) {
		transitioning.animator?.add {[weak self] in
			finish && $0 ? self?.finish() : self?.cancel()
		}
		if !finish {
			transitioning.animator?.play(with: .init(duration: duration.map { .absolute($0) }, isReversed: true))
		} else {
			transitioning.animator?.play(with: .init(duration: duration.map { .absolute($0) }))
		}
	}
	
	override open func update(_ percentComplete: CGFloat) {
		super.update(percentComplete)
		transitioning.animator?.progress = Double(percentComplete)
	}
}
