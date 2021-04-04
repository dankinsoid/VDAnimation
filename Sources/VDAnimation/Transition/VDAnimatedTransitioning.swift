//
//  VDAnimatedTransitioning.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

open class VDAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
	
	public var transitionType: TransitionType
	public var duration: TimeInterval
	public var curve: BezierCurve
	public var animation: VDTransition<Context, VDAnimationProtocol>?
	public var animator: VDAnimationProtocol?
	private var completion: ((Bool) -> Void)?
	
	public init(_ transitionType: TransitionType, duration: TimeInterval, curve: BezierCurve, animation: VDTransition<Context, VDAnimationProtocol>?) {
		self.transitionType = transitionType
		self.duration = duration
		self.curve = curve
		self.animation = animation
		super.init()
	}
	
	open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		duration
	}
	
	open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let animation = prepareAnimation(for: transitionContext) else {
			transitionContext.completeTransition(false)
			return
		}
		guard !transitionContext.isInteractive else { return }
		animation.start {[weak self] in
			self?.animationCompleted($0)
		}
	}
	
	open func animationCompleted(_ transitionCompleted: Bool) {
		animator = nil
		completion?(transitionCompleted)
		completion = nil
	}
	
	open func prepareAnimation(for transitionContext: UIViewControllerContextTransitioning) -> VDAnimationProtocol? {
		if let result = animator {
			return result
		}
		guard let toVc = transitionContext.viewController(forKey: .to), let fromVc = transitionContext.viewController(forKey: .from) else {
			return nil
		}
		let inView = transitionContext.containerView
		toVc.loadViewIfNeeded()
		fromVc.loadViewIfNeeded()
		let toView: UIView = toVc.view
		let fromView: UIView = fromVc.view
		
		let changing = transitionType.show ? toView : fromView
		let stable = transitionType.show ? fromView : toView
		
		if stable.window == nil {
			inView.addSubview(stable)
			stable.frame = inView.bounds
			stable.layoutIfNeeded()
		}
		inView.addSubview(changing)
		changing.frame = inView.bounds
		changing.layoutIfNeeded()
		
		let changingViews = [changing] + changing.allSubviews()
		let stableViews = [stable] + stable.allSubviews()
		
		let changingIds = changingViews.mapDictionary { ($0.transition.id, $0) }
		var pares = stableViews.mapDictionary { ($0, $0.transition.id) }.compactMapValues { changingIds[$0] }
		
		if pares.isEmpty, animation == nil {
			pares[stable] = changing
		}
		
		let properties: [UIView: Properties]
		if !pares.isEmpty {
			properties = self.properties(pares: pares, stable: stable, stableViews: stableViews, changing: changing, changingViews: changingViews)
		} else {
			properties = [:]
		}
		
		let main: VDAnimationProtocol?
		
		if !properties.isEmpty {
			main = Animate {[transitionType] in
				if transitionType.show {
					changingViews.forEach {
						$0.transition.modifier?.final($0)
					}
					stableViews.forEach {
						$0.transition.modifier?[transitionType.inverted]($0)
					}
				} else {
					stableViews.forEach {
						$0.transition.modifier?.final($0)
					}
					changingViews.forEach {
						$0.transition.modifier?[transitionType]($0)
					}
				}
				properties.forEach {
					$0.value.apply(for: $0.key, .to)
				}
			}
		} else {
			main = nil
		}
		
		let duration = transitionDuration(using: transitionContext)
		
		let animation: VDAnimationProtocol
		
		switch (main, self.animation) {
		case (nil, nil):
			return nil
		case (nil, .some(let second)):
			let context = Context(fromVC: fromVc, toVC: toVc, type: transitionType, container: inView)
			animation = second[transitionType](context)
		case (.some(let first), nil):
			animation = first
		case (.some(let first), .some(let second)):
			let context = Context(fromVC: fromVc, toVC: toVc, type: transitionType, container: inView)
			let additional = second[transitionType](context)
			animation = Parallel {
				first
				additional
			}
		}
		
		properties.forEach {
			$0.value.apply(for: $0.key, .from)
		}
		
		if transitionType.show {
			changingViews.forEach {
				$0.transition.modifier?[transitionType]($0)
			}
		} else {
			stableViews.forEach {
				$0.transition.modifier?[transitionType.inverted]($0)
			}
		}
		
		animator = animation.duration(duration).curve(curve)
		
		completion = {[transitionType] in
			if $0 {
				if transitionType.show {
					stableViews.forEach {
						$0.transition.modifier?.final($0)
						properties[$0]?.apply(for: $0, .from)
					}
				} else if transitionType != .set {
					changing.removeFromSuperview()
				}
			} else {
				stableViews.forEach {
					$0.transition.modifier?.final($0)
					properties[$0]?.apply(for: $0, .to)
				}
				changingViews.forEach {
					$0.transition.modifier?.final($0)
					properties[$0]?.apply(for: $0, .from)
				}
			}
			transitionContext.completeTransition($0)
		}
		return animator
	}
	
	private func properties(pares: [UIView: UIView], stable: UIView, stableViews: [UIView], changing: UIView, changingViews: [UIView]) -> [UIView: Properties] {
		var transforms: [UIView: CGAffineTransform] = [:]
		
		self.transforms(stable: stable, pares: pares, transforms: &transforms)
		
		var properties: [UIView: Properties] = [:]
		
		stableViews.forEach {
			properties[$0] = Properties()
			if let transform = transforms[$0] {
				properties[$0] = moveProperty(transform: transform, fromCurrent: transitionType.show, view: $0)
			}
		}
		changingViews.forEach {
			properties[$0] = Properties()
			if let transform = transforms[$0] {
				properties[$0] = moveProperty(transform: transform, fromCurrent: !transitionType.show, view: $0)
			}
		}
		
		if !properties.isEmpty || self.animation == nil {
			if transitionType.show {
				properties[changing, default: .init()].set(keyPath: \.alpha, from: 0, to: 1)
			} else {
				properties[changing, default: .init()].set(keyPath: \.alpha, from: 1, to: 0)
			}
		}
		pares.forEach {
			set(\.layer.cornerRadius, stable: $0.key, changing: $0.value, transitionType: transitionType, properties: &properties)
			set(\.backgroundColor, stable: $0.key, changing: $0.value, transitionType: transitionType, properties: &properties)
		}
		
		return properties
	}
	
	private func moveProperty(transform: CGAffineTransform, fromCurrent: Bool, view: UIView) -> Properties {
		var property = Properties()
		let new = view.transform.added(transform)
		property.set(keyPath: \.transform, from: fromCurrent ? view.transform : new, to: fromCurrent ? new : view.transform)
		return property
	}
	
	func set<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<UIView, T>, stable: UIView, changing: UIView, transitionType: TransitionType, properties: inout [UIView: Properties]) {
		guard stable[keyPath: keyPath] != changing[keyPath: keyPath] else {
			return
		}
		if transitionType.show {
			properties[stable, default: .init()].set(keyPath: keyPath, from: stable[keyPath: keyPath], to: changing[keyPath: keyPath])
			properties[changing, default: .init()].set(keyPath: keyPath, from: stable[keyPath: keyPath], to: changing[keyPath: keyPath])
		} else {
			properties[stable, default: .init()].set(keyPath: keyPath, from: changing[keyPath: keyPath], to: stable[keyPath: keyPath])
			properties[changing, default: .init()].set(keyPath: keyPath, from: changing[keyPath: keyPath], to: stable[keyPath: keyPath])
		}
	}
	
	public enum Direction {
		case from, to
		
		public var inverted: Direction {
			switch self {
			case .from: return .to
			case .to: return .from
			}
		}
	}
	
	private func transforms(stable: UIView, pares: [UIView: UIView], transforms: inout [UIView: CGAffineTransform]) {
		if let changing = pares[stable] {
			let tr = transform(stable: stable, changing: changing)
			zip([tr.1, tr.0], [changing, stable]).forEach {
				var result = $0.0
				if let parent = $0.1.superview, let parentTransform = transforms[parent] {
					result = result.added(parentTransform.inverted())
				}
				transforms[$0.1] = result
			}
		}
		for view in stable.subviews {
			self.transforms(stable: view, pares: pares, transforms: &transforms)
		}
	}
	
	private func transform(stable: UIView, changing: UIView) -> (CGAffineTransform, CGAffineTransform) {
		let stableFrame = stable.convert(stable.bounds, to: stable.window)
		let changingFrame = changing.convert(changing.bounds, to: changing.window)
		
		let scale = CGSize(
			width: changingFrame.width / (stableFrame.width == 0 ? 1 : stableFrame.width),
			height: changingFrame.height / (stableFrame.height == 0 ? 1 : stableFrame.height)
		)
		let transition = CGPoint(
			x: (changingFrame.midX - stableFrame.midX),
			y: (changingFrame.midY - stableFrame.midY)
		)
		#warning("anchorPoint")
		return (
			CGAffineTransform.identity
				.scaledBy(x: scale.width, y: scale.height)
				.added(.translate(transition.x, transition.y)),
			
			CGAffineTransform.identity
				.scaledBy(x: 1 / (scale.width == 0 ? 1 : scale.width), y: 1 / (scale.height == 0 ? 1 : scale.height))
				.added(.translate(-transition.x, -transition.y))
		)
	}
	
	public struct Properties {
		private var properties: [((UIView, Any) -> Void, Any, Any)] = []
		public var isEmpty: Bool { properties.isEmpty }
		public init() {}
		
		public mutating func set<V: UIView, T>(keyPath: ReferenceWritableKeyPath<V, T>, from: T, to: T) {
			properties.append(
				(
					{
						guard let value = $1 as? T, let view = $0 as? V else { return }
						view[keyPath: keyPath] = value
					},
					from,
					to
				)
			)
		}
		
		public func apply(for view: UIView, _ key: Direction) {
			properties.forEach {
				$0.0(view, key == .from ? $0.1 : $0.2)
			}
		}
	}
	
	public struct Context {
		public let fromVC: UIViewController
		public let toVC: UIViewController
		public let type: TransitionType
		public let container: UIView
	}
}
