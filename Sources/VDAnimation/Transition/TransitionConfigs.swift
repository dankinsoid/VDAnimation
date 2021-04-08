//
//  TransitionConfigs.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

public protocol ViewTransitable: UIView {}
public protocol ViewControllerTransitable: UIViewController {}

extension UIView: ViewTransitable {}
extension UIViewController: ViewControllerTransitable {}

extension ViewTransitable {
	public var transition: ViewTransitionConfig {//<Self> {
		if let result = objc_getAssociatedObject(self, &transitionKey) as? ViewTransitionConfig {//<Self> {
			return result
		}
		let result = ViewTransitionConfig()//<Self>()
		objc_setAssociatedObject(self, &transitionKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
	}
}

extension ViewControllerTransitable {
	public var transition: VСTransitionConfig {
		get {
			if let result = objc_getAssociatedObject(self, &transitionVCKey) as? VСTransitionConfig {//<Self> {
				return result
			}
			let result = VСTransitionConfig(self)
			objc_setAssociatedObject(self, &transitionVCKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return result
		}
		set {
			newValue.vc = self
			objc_setAssociatedObject(self, &transitionVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

private var transitionKey = "transitionKey"
private var transitionVCKey = "transitionVCKey"

public final class ViewTransitionConfig {//<View: UIView> {
	public var id: String = UUID().uuidString
	public var modifier: VDTransition<UIView>?
	init() {}
}

public final class VСTransitionConfig {
	public weak var vc: UIViewController? {
		didSet {
			if isEnabled { setEnabled() }
		}
	}
	private lazy var delegate = VDTransitioningDelegate()
	private weak var previousTransitionDelegate: UIViewControllerTransitioningDelegate?
	
	public var duration: TimeInterval {
		get { delegate.duration }
		set { delegate.duration = newValue }
	}
	public var curve: BezierCurve {
		get { delegate.curve }
		set { delegate.curve = newValue }
	}
	public var modifier: VDTransition<UIView> {
		get { vc?.view?.transition.modifier ?? .identity }
		set { vc?.view?.transition.modifier = newValue }
	}
	public var animation: ((VDAnimatedTransitioning.Context) -> VDAnimationProtocol)? {
		get { delegate.additional }
		set { delegate.additional = newValue }
	}
	public var interactive: TransitionInteractivity? {
		get { delegate.interactivity }
		set { delegate.interactivity = newValue }
	}
	public var containerModifier: VDTransition<UIView> {
		get { delegate.containerModifier }
		set { delegate.containerModifier = newValue }
	}
	public var inContainer: ((UIView, UIViewController) -> Void)? {
		get { delegate.inContainer }
		set { delegate.inContainer = newValue }
	}
	
	public var isEnabled = false {
		didSet {
			guard isEnabled != oldValue else { return }
			if isEnabled {
				setEnabled()
			} else {
				vc?.transitioningDelegate = previousTransitionDelegate
				if delegate.previousNavigationDelegate != nil {
					(vc as? UINavigationController)?.delegate = delegate.previousNavigationDelegate
				}
				if delegate.previousTabDelegate != nil {
					(vc as? UITabBarController)?.delegate = delegate.previousTabDelegate
				}
			}
		}
	}
	
	private func setEnabled() {
		if interactive == nil, vc as? UINavigationController != nil {
			interactive = .edges(.left)
		}
		
		previousTransitionDelegate = vc?.transitioningDelegate
		vc?.transitioningDelegate = delegate
		vc?.modalPresentationStyle = .overCurrentContext
		
		delegate.previousNavigationDelegate = (vc as? UINavigationController)?.delegate
		delegate.previousTabDelegate = (vc as? UITabBarController)?.delegate
		(vc as? UINavigationController)?.delegate = delegate
		(vc as? UITabBarController)?.delegate = delegate
	}
	
	public init(_ vc: UIViewController) {
		self.vc = vc
	}
}

extension UIViewController {
	
	public func present(_ viewController: UIViewController, transition: VDTransition<UIView>, interactive: TransitionInteractivity?, animated: Bool = true, completion: (() -> Void)? = nil) {
		viewController.transition.isEnabled = true
		viewController.transition.modifier = transition
		viewController.transition.interactive = interactive
		let duration = viewController.transition.duration
		if !animated {
			viewController.transition.duration = 0.0001
		}
		present(viewController, animated: true) {
			if !animated {
				viewController.transition.duration = duration
			}
			completion?()
		}
	}
	
	public func present(_ viewController: UIViewController, transitions: [UIView: UIView], interactive: TransitionInteractivity?, animated: Bool = true, completion: (() -> Void)? = nil) {
		viewController.loadViewIfNeeded()
		viewController.transition.isEnabled = true
		transitions.forEach {
			$0.key.transition.id = $0.value.transition.id
		}
		viewController.transition.interactive = interactive
		let duration = viewController.transition.duration
		if !animated {
			viewController.transition.duration = 0.0001
		}
		present(viewController, animated: true) {
			if !animated {
				viewController.transition.duration = duration
			}
			completion?()
		}
	}
}
