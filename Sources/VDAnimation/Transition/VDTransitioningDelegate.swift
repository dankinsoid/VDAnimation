//
//  VDTransitioningDelegate.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import Foundation
import UIKit

open class VDTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
	
	open weak var owner: UIViewController? {
		didSet { configureInteractive(old: interactivity) }
	}
	
	open var duration: TimeInterval = 0.25
	open var curve: BezierCurve = .easeInOut
	open var parallelAnimation: TransitionParallelAnimation?
	open var modifier: VDTransition<UIView>?
	open var applyModifierOnBothVC = false
	open var containerModifier: VDTransition<UIView> = .identity
	open var prepare: ((VDTransitionContext) -> Void)?
	open var inAnimation: ((VDTransitionContext) -> Void)?
	open var completion: ((VDTransitionContext, Bool) -> Void)?
	open var currentTransitioning: VDAnimatedTransitioning?
	open var restoreDisappearedViews: Bool = true
	var isCustom = true
	
	open var isInteractive = false
	open var appearInteractiveTransition: InteractiveDriver?
	open var disappearInteractiveTransition: InteractiveDriver?
	open var interactivity: TransitionInteractivity = .none {
		didSet {
			configureInteractive(old: oldValue)
		}
	}
	
	var disappearStates: [UIView: (UIView) -> Void] = [:]
	
	public weak var previousDelegate: AnyObject?
	
	public init(_ owner: UIViewController?) {
		self.owner = owner
		if isCustom {
			applyModifierOnBothVC = (owner as? CustomTransitionViewController)?.applyModifierOnBothViews ?? false
		}
		super.init()
	}
	
	open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transitioning(for: .present, presenting: presented)
	}
	
	open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transitioning(for: .dismiss, presenting: nil)
	}
	
	open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		UIPresentationController(presentedViewController: presented, presenting: presenting)
	}
	
	open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		isInteractive ? appearInteractiveTransition : nil//(animator as? VDAnimatedTransitioning)
	}
	
	open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		isInteractive ? disappearInteractiveTransition : nil//(animator as? VDAnimatedTransitioning)
	}
	
	open func transitioning(for type: TransitionType, presenting: UIViewController?) -> VDAnimatedTransitioning {
		let result = VDAnimatedTransitioning(type, delegate: self, presenting: presenting)
		currentTransitioning = result
		return result
	}
	
	open func transitioning(for controller: UIViewController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		guard isInteractive, let transitioning = animationController as? VDAnimatedTransitioning else {
			return nil//animationController as? VDAnimatedTransitioning
		}
		currentTransitioning = transitioning
		return transitioning.transitionType.show ? appearInteractiveTransition : disappearInteractiveTransition
	}
	
	private func configureInteractive(old: TransitionInteractivity) {
		guard isCustom, let vc = owner as? CustomTransitionViewController else { return }
		let container = vc.transitionContainerView()
		old.remove(container: container, vc: vc, delegate: self)
		configureInteractive(in: container)
	}
	
	func configureInteractive(in view: UIView) {
		guard let controller = owner else { return }
		disappearInteractiveTransition = interactivity.disappear?.driver(container: view, for: controller, delegate: self)
		appearInteractiveTransition = interactivity.appear?.driver(container: view, for: controller, delegate: self)
	}
	
	func cancel() {
		currentTransitioning?.animator?.stop(at: .start)
		isInteractive = false
	}
}
