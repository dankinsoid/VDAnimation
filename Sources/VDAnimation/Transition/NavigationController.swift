//
//  NavigationController.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

extension VDTransitioningDelegate: UINavigationControllerDelegate {
	
	open func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		guard let transitioninig = animationController as? VDAnimatedTransitioning else { return nil }
		if panDriver == nil {
			
			let pan = UIScreenEdgePanGestureRecognizer()
			pan.edges = .left
			navigationController.view.addGestureRecognizer(pan)
			let transition = VDAnimationTransition(transitioning: transitioninig, delegate: self)
			transition.vc = navigationController
			transition.completion = {[weak self] in
				if $0 {
					pan.view?.removeGestureRecognizer(pan)
					self?.panDriver = nil
				}
			}
			panDriver = PanInteractiveTransitionDriver(recognizer: pan, transition: transition) { pan in
				pan.location(in: pan.view).x / (pan.view?.frame.width ?? 1)
			}
		}
		panDriver?.transition.transitioning = transitioninig
		return isInteractive ? panDriver?.transition : nil
	}
	
	open func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		switch operation {
		case .push:	return transitioning(for: .push)
		case .pop:	return transitioning(for: .pop)
		default:		return nil
		}
	}
	
	open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		previousNavigationDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
	}
	
	open func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		previousNavigationDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
	}
	
	open func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
		previousNavigationDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .all
	}
	
	open func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
		previousNavigationDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
	}
}
