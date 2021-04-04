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
	
	public var transition: ViewTransitionConfig<Self> {
		if let result = objc_getAssociatedObject(self, &transitionKey) as? ViewTransitionConfig<Self> {
			return result
		}
		let result = ViewTransitionConfig<Self>()
		objc_setAssociatedObject(self, &transitionKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
	}
}

extension ViewControllerTransitable {
	public var transition: VСTransitionConfig<Self> {
		if let result = objc_getAssociatedObject(self, &transitionVCKey) as? VСTransitionConfig<Self> {
			return result
		}
		let result = VСTransitionConfig(self)
		objc_setAssociatedObject(self, &transitionVCKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
	}
}

private var transitionKey = "transitionKey"
private var transitionVCKey = "transitionVCKey"

public final class ViewTransitionConfig<View: UIView> {
	public var id: String = UUID().uuidString
	public var modifier: VDTransition<View, Void>?
	init() {}
}

public final class VСTransitionConfig<VC: UIViewController> {
	public weak var vc: VC?
	private var delegate: VDTransitioningDelegate?
	
	public var duration: TimeInterval = 0.25 {
		didSet { delegate?.duration = duration }
	}
	public var curve: BezierCurve = .easeInOut {
		didSet { delegate?.curve = curve }
	}
	public var animation: VDTransition<VDAnimatedTransitioning.Context, VDAnimationProtocol>? {
		didSet { delegate?.additional = animation }
	}
	
	public var isEnabled = false {
		didSet {
			guard isEnabled != oldValue else { return }
			if isEnabled {
				delegate = VDTransitioningDelegate()
				delegate?.duration = duration
				delegate?.curve = curve
				delegate?.additional = animation
				
				vc?.transitioningDelegate = delegate
				vc?.modalPresentationStyle = .overCurrentContext
				
				delegate?.previousNavigationDelegate = (vc as? UINavigationController)?.delegate
				delegate?.previousTabDelegate = (vc as? UITabBarController)?.delegate
				(vc as? UINavigationController)?.delegate = delegate
				(vc as? UITabBarController)?.delegate = delegate
			} else {
				if delegate?.previousNavigationDelegate != nil {
					(vc as? UINavigationController)?.delegate = delegate?.previousNavigationDelegate
				}
				if delegate?.previousTabDelegate != nil {
					(vc as? UITabBarController)?.delegate = delegate?.previousTabDelegate
				}
				delegate = nil
			}
		}
	}
	
	public init(_ vc: VC) {
		self.vc = vc
	}
}
