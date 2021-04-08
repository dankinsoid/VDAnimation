//
//  VDTransitioningDelegate.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import Foundation
import UIKit

open class VDTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
	
	open var duration: TimeInterval = 0.25
	open var curve: BezierCurve = .easeInOut
	open var additional: ((VDAnimatedTransitioning.Context) -> VDAnimationProtocol)?
	open var isInteractive = false
	open var interactiveTransitioning: UIViewControllerInteractiveTransitioning?
	open var interactivity: TransitionInteractivity?
	open var containerModifier: VDTransition<UIView> = .identity
	open var inContainer: ((UIView, UIViewController) -> Void)?
	
	weak var previousNavigationDelegate: UINavigationControllerDelegate?
	weak var previousTabDelegate: UITabBarControllerDelegate?
	
	open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transitioning(for: .present)
	}
	
	open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transitioning(for: .dismiss)
	}
	
	open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		UIPresentationController(presentedViewController: presented, presenting: presenting)
	}
	
	open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		isInteractive ? interactiveTransitioning : nil
	}
	
	open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		isInteractive ? interactiveTransitioning : nil
	}
	
	open func transitioning(for type: TransitionType) -> VDAnimatedTransitioning {
		VDAnimatedTransitioning(type, delegate: self)
	}
}
