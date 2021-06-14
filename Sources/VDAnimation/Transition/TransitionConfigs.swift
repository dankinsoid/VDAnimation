//
//  TransitionConfigs.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import VDKit

extension VСTransitionConfig {
	
	public static func pageSheet(from edge: Edges = .bottom, minOffset: CGFloat = 10, cornerRadius: CGFloat = 10, backScale: Double = 0.915, containerColor: UIColor = #colorLiteral(red: 0.21, green: 0.21, blue: 0.23, alpha: 0.37)) -> VСTransitionConfig {
		
		let result = VСTransitionConfig()
		result.isEnabled = true
		result.modifier = .edge(edge)
		result.containerModifier = .background(containerColor)
		result.restoreDisappearedViews = false
		
		let insets = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero)[edge.opposite]
		let size = UIScreen.main.bounds.size[edge.axe] * CGFloat(1 - backScale) / 2
		let offset = max(size, insets) + minOffset
		let dif = offset - insets
		
		var constraint: NSLayoutConstraint?
		
		result.prepare = {[weak result] in
			guard $0.type.show else { return }
			$0.bottomVC.transition.modifier = VDTransition.scale(backScale).corner(radius: cornerRadius)
			$0.bottomVC.view.clipsToBounds = true
			$0.bottomVC.view.layer.cornerRadius = UIScreen.main.cornerRadius
			$0.topVC.view.translatesAutoresizingMaskIntoConstraints = false
			
			if let topView = $0.topVC.view, let superView = topView.superview {
				var edges = Edges.allCases
				if let i = edges.firstIndex(of: edge.opposite) {
					edges.remove(at: i)
				}
				edges.forEach { edge in
					topView.edge(edge, to: superView)
				}
				constraint = topView.edge(edge.opposite, to: superView, priority: .init(990))
			}
			
			$0.topVC.view.clipsToBounds = true
			$0.topVC.view.layer.cornerRadius = cornerRadius
			$0.topVC.view.layer.maskedCorners = .edge(edge.opposite)
			if $0.type == .present {
				let recognizer = TapRecognizer()
				$0.container.addGestureRecognizer(recognizer)
				recognizer.onTap = {
					result?.vc?.dismiss(animated: true, completion: nil)
				}
			}
		}
		
		result.interactive.disappear = .swipe(to: .init(edge)) {
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
		result.interactive.disappear = .edges(.init(edge.opposite))
		return result
	}
	
	public static func fade(interactive: TransitionInteractivity = .none) -> VСTransitionConfig {
		let result = VСTransitionConfig()
		result.isEnabled = true
		result.modifier = .opacity
		result.interactive = interactive
		return result
	}
	
	public static func push(from edge: Edges = .right, swipeFromEdge: Bool = false, swipeToShow: Bool = false, containerColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1), backViewControllerOffset offset: RelationValue<CGFloat> = .relative(0.7)) -> VСTransitionConfig {
		let transition = VСTransitionConfig()
		transition.applyModifierOnBothVC = true
		transition.modifier = .asymmetric(appear: .edge(edge.opposite, offset: offset), disappear: .edge(edge))
		transition.containerModifier = .background(containerColor)
		transition.interactive.disappear = .swipe(to: UIRectEdge(edge), fromEdges: swipeFromEdge, in: nil, observe: nil)
		if swipeToShow {
			transition.interactive.appear = .swipe(to: UIRectEdge(edge.opposite), fromEdges: swipeFromEdge, in: nil, observe: nil)
		}
		let id = UUID().uuidString
		transition.prepare = {
			guard containerColor != .clear else { return }
			let view = $0.container.subviews.first(where: { $0.accessibilityIdentifier == id }) ?? UIView()
			view.accessibilityIdentifier = id
			view.isUserInteractionEnabled = false
			view.backgroundColor = .clear
			view.transition.modifier = .background(containerColor)
			if view.superview == nil {
				view.frame = $0.container.bounds
				$0.container.addSubview(view)
			}
			if let i = $0.container.subviews.firstIndex(of: $0.topView),
				 let j = $0.container.subviews.firstIndex(of: view),
				 i <  j {
				$0.container.exchangeSubview(at: i, withSubviewAt: j)
			}
		}
		transition.completion = { context, _ in
			context.container.subviews
				.filter { $0.accessibilityIdentifier == id }
				.forEach { $0.removeFromSuperview() }
		}
		transition.isEnabled = true
		return transition
	}
}

extension UIViewController {
	
	public func present(_ viewController: UIViewController, transition: VDTransition<UIView>, interactive: TransitionInteractivity?, animated: Bool = true, completion: (() -> Void)? = nil) {
		viewController.transition.isEnabled = true
		viewController.transition.modifier = transition
		viewController.transition.interactive = interactive ?? .none
		let duration = viewController.transition.duration
		if !animated {
			viewController.transition.duration = 0
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
		viewController.transition.interactive = interactive ?? .none
		let duration = viewController.transition.duration
		if !animated {
			viewController.transition.duration = 0
		}
		present(viewController, animated: true) {
			if !animated {
				viewController.transition.duration = duration
			}
			completion?()
		}
	}
}

fileprivate class TapRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
	var onTap: () -> Void = {}
	
	init() {
		super.init(target: nil, action: nil)
		delegate = self
		addTarget(self, action: #selector(handle))
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		gestureRecognizer.view === touch.view
	}
	
	@objc private func handle(_ gestureRecognizer: UIGestureRecognizer) {
		if gestureRecognizer.state == .recognized {
			onTap()
		}
	}
}
