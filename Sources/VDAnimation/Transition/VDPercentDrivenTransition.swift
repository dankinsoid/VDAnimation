//
//  VDPercentDrivenTransition.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

open class VDPercentDrivenTransition: UIPercentDrivenInteractiveTransition {
	
	public var completion: ((Bool) -> Void)?
	public weak var vc: UIViewController?
	public weak var delegate: VDTransitioningDelegate?
	public var transitioning: VDAnimatedTransitioning
	private(set) var wasBegun = false
	
	public init(transitioning: VDAnimatedTransitioning, delegate: VDTransitioningDelegate?) {
		self.transitioning = transitioning
		self.delegate = delegate
		super.init()
	}
	
	open func begin() {
		guard !wasBegun else { return }
		wasBegun = true
		delegate?.isInteractive = true
		if transitioning.animator?.isRunning == true {
			transitioning.animator?.pause()
			return
		}
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
		guard wasBegun else { return }
		super.cancel()
		wasBegun = false
		transitioning.animator?.cancel()
		delegate?.isInteractive = false
		transitioning.animationCompleted(false)
		completion?(false)
	}
	
	override open func finish() {
		guard wasBegun else { return }
		super.finish()
		wasBegun = false
		transitioning.animator?.stop(at: .end)
		delegate?.isInteractive = false
		transitioning.animationCompleted(true)
		completion?(true)
	}
	
	open func complete(duration: Double?, finish: Bool) {
		guard transitioning.animator != nil else {
			finish ? self.finish() : self.cancel()
			return
		}
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
		if transitioning.animator?.isRunning == true {
			transitioning.animator?.pause()
		}
		transitioning.animator?.progress = Double(percentComplete)
	}
}
