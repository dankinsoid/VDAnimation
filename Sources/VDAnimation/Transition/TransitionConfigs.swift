//
//  TransitionConfigs.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

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
			vc?.view?.transition.modifier = modifier ?? vc?.view?.transition.modifier
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
	public var modifier: VDTransition<UIView>? {
		didSet {
			vc?.view?.transition.modifier = modifier ?? vc?.view?.transition.modifier
		}
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
	public var prepare: ((VDTransitionContext) -> Void)? {
		get { delegate.prepare }
		set { delegate.prepare = newValue }
	}
	public var restoreDisappearedViews: Bool {
		get { delegate.restoreDisappearedViews }
		set { delegate.restoreDisappearedViews = newValue }
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
		guard vc != nil else { return }
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
	
	public init() {}
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

extension VСTransitionConfig {
	
	public static func pageSheet(from edge: Edges = .bottom, minOffset: CGFloat = 10, cornerRadius: CGFloat = 10, backScale: Double = 0.9, containerColor: UIColor = .black.withAlphaComponent(0.2)) -> VСTransitionConfig {
		
		let result = VСTransitionConfig()
		result.isEnabled = true
		result.modifier = .edge(edge)
		result.containerModifier = .background(containerColor)
		result.restoreDisappearedViews = false
		
		let insets = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero)[edge.opposite]
		let size = UIScreen.main.bounds.size[edge.axe] * CGFloat(1 - backScale) / 2
		let offset = max(size, insets) + minOffset
		let dif = offset - insets
		
		var constraint: Constraints<UIView>?
		
		result.prepare = {
			guard $0.type.show else { return }
			$0.bottomVC.transition.modifier = .scale(backScale).corner(radius: cornerRadius)
			$0.bottomVC.view.clipsToBounds = true
			$0.bottomVC.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
			$0.topVC.view.ignoreAutoresizingMask()
			$0.topVC.view.edges(Edges.Set.all.subtracting(.init(edge.opposite))) =| 0
			constraint = $0.topVC.view.edges(.init(edge.opposite)) =| offset
			$0.topVC.view.clipsToBounds = true
			$0.topVC.view.layer.cornerRadius = cornerRadius
			$0.topVC.view.layer.maskedCorners = .edge(edge.opposite)
		}
		
		result.interactive = .swipe(to: .init(edge)) {
			let constant = (edge == .right || edge == .bottom ? 1 : -1) * (offset - ($0 > 0 ? 0 : 2 * dif * atan(-$0 / dif) / .pi))
			if constant != constraint?.constant {
				constraint?.constant = constant
			}
		}
		return result
	}

	public static func edge(_ edge: Edges = .bottom) -> VСTransitionConfig {
		let result = VСTransitionConfig()
		result.isEnabled = true
		result.modifier = .edge(edge)
		result.interactive = .edges(.init(edge.opposite))
		return result
	}
	
	public static func fade(interactive: TransitionInteractivity? = nil) -> VСTransitionConfig {
		let result = VСTransitionConfig()
		result.isEnabled = true
		result.modifier = .opacity
		result.interactive = interactive
		return result
	}
}
