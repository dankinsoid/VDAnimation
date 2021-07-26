//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.07.2021.
//

import UIKit

public protocol CustomTransitionViewController: UIViewController {
	func transitionContainerView() -> UIView
	func setTransition(delegate: VDTransitioningDelegate)
	var defaultDelegate: AnyObject? { get set }
	var applyModifierOnBothViews: Bool { get }
	var defaultInteractive: TransitionInteractivity? { get }
}

extension CustomTransitionViewController {
	public func transitionContainerView() -> UIView {
		loadViewIfNeeded()
		return view
	}
}
