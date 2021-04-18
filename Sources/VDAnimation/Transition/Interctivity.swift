//
//  Interctivity.swift
//  VDTransition
//
//  Created by Данил Войдилов on 07.04.2021.
//

import UIKit
import ConstraintsOperators

public struct TransitionInteractivity {
	
	public var appear: Single? {
		get { _appear }
		set { _appear = newValue?.show(true) }
	}
	public var disappear: Single? {
		get { _disappear }
		set { _disappear = newValue?.show(false) }
	}
	private var _appear: Single?
	private var _disappear: Single?
	
	public var isNone: Bool { _appear == nil && _disappear == nil }
	
	public var inverted: TransitionInteractivity {
		TransitionInteractivity(appear: _disappear, disappear: _appear)
	}
	
	public init(appear: Single?, disappear: Single?) {
		self._appear = appear?.show(true)
		self._disappear = disappear?.show(false)
	}
	
	public static func appear(_ appear: Single) -> TransitionInteractivity {
		TransitionInteractivity(appear: appear, disappear: nil)
	}
	
	public static func disappear(_ disappear: Single) -> TransitionInteractivity {
		TransitionInteractivity(appear: nil, disappear: disappear)
	}
	
	public static var none: TransitionInteractivity {
		TransitionInteractivity(appear: nil, disappear: nil)
	}
	
	public func remove(container: UIView, vc: UIViewController, delegate: VDTransitioningDelegate) {
		_appear?.remove?(container, vc, delegate)
		_disappear?.remove?(container, vc, delegate)
	}
	
//	public static func edges(_ edge: UIRectEdge, of view: UIView? = nil) -> TransitionInteractivity {
//		TransitionInteractivity { view, vc, delegate, transitioning in
//			let id = "TransitionInteractivityEdge"
//			let pan = (view.gestureRecognizers?.first(where: { $0.id == id }) as? UIScreenEdgePanGestureRecognizer) ?? UIScreenEdgePanGestureRecognizer()
//			pan.id = id
//			pan.edges = edge
//			if pan.view == nil {
//				view.addGestureRecognizer(pan)
//			}
//			pan.isEnabled = true
//			let transition = (delegate.interactiveTransitioning as? PanInteractiveTransitionDriver) ??
//				PanInteractiveTransitionDriver(recognizer: pan, edge: edge, transitioning: transitioning, delegate: delegate)
//			transition.vc = vc
//			transition.transitioning = transitioning
//			return transition
//		}
//	}
}

extension TransitionInteractivity {
	
	public static func slide(from: UIRectEdge = .left, to: UIRectEdge = .right, fromEdges: Bool = false, in container: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity {
		.init(appear: .swipe(to: from, fromEdges: fromEdges, in: container, observe: observe), disappear: .swipe(to: to, fromEdges: fromEdges, in: container, observe: observe))
	}
}

extension TransitionInteractivity {
	
	public struct Single {
		private var _transition: (UIView, UIViewController, VDTransitioningDelegate) -> InteractiveDriver
		public var remove: ((UIView, UIViewController, VDTransitioningDelegate) -> Void)?
		var isAppear: Bool
		
		public init(transition: @escaping (UIView, UIViewController, VDTransitioningDelegate) -> InteractiveDriver, remove: ((UIView, UIViewController, VDTransitioningDelegate) -> Void)?) {
			_transition = transition
			self.remove = remove
			isAppear = true
		}
		
		public func driver(container: UIView, for vc: UIViewController, delegate: VDTransitioningDelegate) -> InteractiveDriver {
			let result = self._transition(container, vc, delegate)
			result.show = self.isAppear
			return result
		}
		
		func show(_ show: Bool) -> Single {
			var result = self
			result.isAppear = show
			return result
		}
	}
}

extension TransitionInteractivity.Single {
	
	public static func edges(_ edge: UIRectEdge, of view: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity.Single {
		swipe(to: edge.inverted, fromEdges: true, in: view, observe: observe)
	}
	
	public static func swipe(to edges: UIRectEdge, in container: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity.Single {
		swipe(to: edges, fromEdges: false, in: container, observe: observe)
	}
	
	static func swipe(to edges: UIRectEdge, fromEdges: Bool, in container: UIView?, observe: ((CGFloat) -> Void)?) -> TransitionInteractivity.Single {
		TransitionInteractivity.Single {[weak container] view, vc, delegate in
			let id = "\(ObjectIdentifier(container ?? view))Swipe"
			let scroll = (view.subviews.first(where: { $0.accessibilityIdentifier == id }) as? SwipeView) ?? SwipeView()
			scroll.accessibilityIdentifier = id
			let key = SwipeView.Instance.Key(edge: edges, startFromEdges: fromEdges)
			guard scroll.instances[key] == nil else {
				return scroll.instances[key]?.driver ?? .dismiss(delegate: delegate)
			}
			if scroll.superview == nil {
				view.addSubview(scroll)
				//				scroll.ignoreAutoresizingMask()
				//				scroll.leading =| 0
				//				scroll.top =| 0
				//				scroll.size =| container ?? view
				scroll.panGestureRecognizer.isEnabled = true
				view.sendSubviewToBack(scroll)
				(container ?? view).addGestureRecognizer(scroll.panGestureRecognizer)
			}
			scroll.delegate = nil
			scroll.frame = (container ?? view).bounds
			scroll.delegate = scroll
			
			if let observer = observe {
				scroll[key].observers.append(observer)
			}
			
			let transition: InteractiveDriver
			
			if delegate.currentTransitioning?.transitionType == .present || delegate.currentTransitioning?.transitionType == .dismiss {
				transition = scroll[key].driver ?? .dismiss(delegate: delegate)
			} else if delegate.currentTransitioning?.transitionType.isNavigation == true ||
					delegate.currentTransitioning == nil && (delegate.owner as? UINavigationController != nil) {
				transition = scroll[key].driver ?? .pop(delegate: delegate)
			} else if delegate.currentTransitioning?.transitionType.isTabs == true ||
					delegate.currentTransitioning == nil && (delegate.owner as? UITabBarController != nil) {
				transition = scroll[key].driver ?? .tab(delegate: delegate)
			} else {
				transition = scroll[key].driver ?? .dismiss(delegate: delegate)
			}
			
			scroll[key].driver = transition
			transition.vc = vc
			transition.delegate = delegate
			return transition
		} remove: {[weak container] view, _, _ in
			let id = "\(ObjectIdentifier(container ?? view).debugDescription)\(edges.rawValue)Swipe"
			if let scroll = view.subviews.first(where: { $0.accessibilityIdentifier == id }) {
				scroll.removeFromSuperview()
			}
		}
	}
	
	public static func driven(by driver: InteractiveDriver) -> TransitionInteractivity.Single {
		TransitionInteractivity.Single(
			transition: { view, vc, delegate in
				driver.delegate = delegate
				driver.vc = vc
				return driver
			},
			remove: nil
		)
	}
}
