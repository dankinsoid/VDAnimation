//
//  Interctivity.swift
//  VDTransition
//
//  Created by Данил Войдилов on 07.04.2021.
//

import UIKit
import ConstraintsOperators

public struct TransitionInteractivity {
	
	public typealias Single = (UIView, UIViewController, VDTransitioningDelegate, VDAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning
	
	public var appear: Single
	public var disappear: Single
	
	public init(_ create: @escaping Single) {
		appear = create
		disappear = create
	}
	
	init(appear: @escaping Single, disappear: @escaping Single) {
		self.appear = appear
		self.disappear = disappear
	}
	
	public static func asymmetric(appear: TransitionInteractivity, disappear: TransitionInteractivity) -> TransitionInteractivity {
		TransitionInteractivity(appear: appear.appear, disappear: disappear.disappear)
	}
	
	public static func edges(_ edge: UIRectEdge, of view: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity {
		swipe(to: edge.inverted, fromEdges: true, in: view, observe: observe)
	}
	
	public static func swipe(to edges: UIRectEdge, in container: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity {
		swipe(to: edges, fromEdges: false, in: container, observe: observe)
	}
	
	public static func slide(from: UIRectEdge = .left, to: UIRectEdge = .right, in container: UIView? = nil, observe: ((CGFloat) -> Void)? = nil) -> TransitionInteractivity {
		asymmetric(appear: swipe(to: from, in: container, observe: observe), disappear: swipe(to: to, in: container, observe: observe))
	}
	
	private static func swipe(to edges: UIRectEdge, fromEdges: Bool, in container: UIView?, observe: ((CGFloat) -> Void)?) -> TransitionInteractivity {
		TransitionInteractivity {[weak container] view, vc, delegate, transitioning in
			let id = "TransitionInteractivitySwipe"
			let scroll = (view.subviews.first(where: { $0.accessibilityIdentifier == id }) as? SwipeView) ?? SwipeView()
			scroll.accessibilityIdentifier = id
			
			if scroll.superview == nil {
				view.addSubview(scroll)
				scroll.ignoreAutoresizingMask()
				scroll.leading =| 0
				scroll.top =| 0
				scroll.panGestureRecognizer.isEnabled = true
			}
			view.sendSubviewToBack(scroll)
			(container ?? view).addGestureRecognizer(scroll.panGestureRecognizer)
			scroll.size =| (container ?? view).frame.size
			scroll.frame = (container ?? view).bounds
			scroll.startFromEdges = fromEdges
			scroll.edges = edges
			
			if let observer = observe {
				scroll.observers.append(observer)
			}
			
			let transition = scroll.driver ?? VDPercentDrivenTransition(transitioning: transitioning, delegate: delegate)
			scroll.driver = transition
			transition.vc = vc
			transition.transitioning = transitioning
			return transition
		}
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

extension UIGestureRecognizer {
	var id: String? {
		get {
			objc_getAssociatedObject(self, &idKey) as? String
		}
		set {
			objc_setAssociatedObject(self, &idKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

private var idKey = "idKeu"

private final class SwipeView: UIScrollView, UIScrollViewDelegate {
	
	weak var driver: VDPercentDrivenTransition?
	private var wasBegan = false
	private var lastPercent: CGFloat?
	private let content = UIView()
	var startFromEdges = false
	private let threshold: CGFloat = 36
	var observers: [(CGFloat) -> Void] = []
	
	private var percent: CGFloat {
		let dif = contentOffset - initialOffset
		if dif.x == 0 {
			return offset / frame.height
		} else {
			return offset / frame.width
		}
	}
	
	private var offset: CGFloat {
		var value: CGFloat
		let offset = contentOffset - initialOffset
		if offset.x == 0 {
			guard edges.contains(.top) || edges.contains(.bottom) else { return 0 }
			value = offset.y
			if edges.contains(.bottom) && edges.contains(.top) {
				value = abs(value)
			} else if edges.contains(.bottom) {
				value = -value
			}
			return value
		} else {
			guard edges.contains(.left) || edges.contains(.right) else { return 0 }
			value = offset.x
			if edges.contains(.right) && edges.contains(.left) {
				value = abs(value)
			} else if edges.contains(.right) {
				value = -value
			}
			return value
		}
	}
	
	private var initialOffset: CGPoint {
		CGPoint(
			x: edges.contains(.right) ? frame.width : 0,
			y: edges.contains(.bottom) ? frame.height : 0
		)
	}

	var edges: UIRectEdge = .left {
		didSet { reset() }
	}
	
	init() {
		super.init(frame: .zero)
		afterInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	private func afterInit() {
		delegate = self
		alpha = 0
		isPagingEnabled = true
		contentInsetAdjustmentBehavior = .never
		isUserInteractionEnabled = false
		isDirectionalLockEnabled = true
		
		addSubview(content)
		content.frame.size = CGSize(width: frame.width * 2, height: frame.height)
		content.ignoreAutoresizingMask()
		content.edges() =| self
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard frame.width > 0, driver?.wasBegun == true else { return }
		defer {
			notify()
		}
		let percent = max(0, min(1, self.percent))
		guard percent != lastPercent else { return }
		lastPercent = percent
		driver?.update(percent)
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		guard driver?.wasBegun == true else { return }
		let percent = self.percent
		lastPercent = percent
		if percent >= 1 {
			driver?.finish()
			reset()
		} else if percent <= 0 {
			driver?.cancel()
			reset()
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		guard driver?.wasBegun == false else { return }
		driver?.begin()
	}
	
	func reset() {
		delegate = nil
		lastPercent = nil
		alwaysBounceVertical = edges.contains(.top) || edges.contains(.bottom)
		alwaysBounceHorizontal = edges.contains(.right) || edges.contains(.left)
		let k = CGSize(
			width: edges.contains(.right) && edges.contains(.left) ? 3 : 2,
			height: edges.contains(.top) && edges.contains(.bottom) ? 3 : 2
		)
		content.width =| width * k.width
		content.height =| height * k.height
		content.frame.size = CGSize(width: frame.width * k.width, height: frame.height * k.height)
		contentOffset = initialOffset
		delegate = self
	}
	
	private func notify() {
		guard !observers.isEmpty else { return }
		let offset = self.offset
		observers.forEach {
			$0(offset)
		}
	}
	
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard startFromEdges else {
			return super.gestureRecognizerShouldBegin(gestureRecognizer)
		}
		let size = gestureRecognizer.view?.frame.size ?? frame.size
		let location = gestureRecognizer.location(in: gestureRecognizer.view ?? self)
		
		let edgeInsets = UIEdgeInsets(
			top: abs(location.y),
			left: abs(location.x),
			bottom: abs(size.height - location.y),
			right: abs(size.width - location.x)
		)
		
		return (
			edges.contains(.right) && edgeInsets.left < threshold ||
			edges.contains(.left) && edgeInsets.right < threshold ||
			edges.contains(.top) && edgeInsets.bottom < threshold ||
			edges.contains(.bottom) && edgeInsets.top < threshold
		) && super.gestureRecognizerShouldBegin(gestureRecognizer)
	}
}

extension UIRectEdge {
	var inverted: UIRectEdge {
		var result: UIRectEdge = []
		if contains(.left) { result.insert(.right) }
		if contains(.right) { result.insert(.left) }
		if contains(.top) { result.insert(.bottom) }
		if contains(.bottom) { result.insert(.top) }
		return result
	}
}
