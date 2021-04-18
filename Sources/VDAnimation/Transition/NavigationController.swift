//
//  NavigationController.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

extension VDTransitioningDelegate: UINavigationControllerDelegate {
	
	open func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		transitioning(for: navigationController, interactionControllerFor: animationController)
	}
	
	open func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		switch operation {
		case .push:	return transitioning(for: .push, presenting: toVC)
		case .pop:	return transitioning(for: .pop, presenting: nil)
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
