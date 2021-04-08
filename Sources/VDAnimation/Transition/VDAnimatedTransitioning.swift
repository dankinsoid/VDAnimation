//
//  VDAnimatedTransitioning.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

open class VDAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
	
	public var transitionType: TransitionType
	private(set) var animator: AnimationDelegateProtocol?
	private var completion: ((Bool) -> Void)?
	private weak var delegate: VDTransitioningDelegate?
	
	public var duration: TimeInterval { delegate?.duration ?? 0 }
	public var curve: BezierCurve { delegate?.curve ?? .linear }
	public var animation: ((Context) -> VDAnimationProtocol)? { delegate?.additional }
	public var interactivity: TransitionInteractivity? { delegate?.interactivity }
	
	public init(_ transitionType: TransitionType, delegate: VDTransitioningDelegate) {
		self.transitionType = transitionType
		self.delegate = delegate
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
		animation.add {[weak self] in
			self?.animationCompleted($0)
		}
		animation.play()
	}
	
	open func animationCompleted(_ transitionCompleted: Bool) {
		animator = nil
		completion?(transitionCompleted)
		completion = nil
	}
	
	open func prepareAnimation(for transitionContext: UIViewControllerContextTransitioning) -> AnimationDelegateProtocol? {
		if let result = animator {
			return result
		}
		guard let toVc = transitionContext.viewController(forKey: .to), let fromVc = transitionContext.viewController(forKey: .from), let delegate = self.delegate else {
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
		
		delegate.inContainer?(inView, transitionType.show ? toVc : fromVc)
		inView.layoutIfNeeded()
		inView.backgroundColor = .clear
		
		prepareInteractive(context: transitionContext)
		
		let appearViews = [toView] + toView.allSubviews()
		let disappearViews = [fromView] + fromView.allSubviews()
		
		let appearIds = appearViews.mapDictionary { ($0.transition.id, $0) }
		let pares = disappearViews.mapDictionary { ($0, $0.transition.id) }.compactMapValues { appearIds[$0] }
	
		var properties: [UIView: Properties] = (appearViews + disappearViews).compactMapDictionary { view in
			view.transition.modifier.map { (view, $0) }
		}
		
		if !pares.isEmpty {
			properties.merge(
				self.properties(pares: pares, disappear: fromView, disappearViews: disappearViews, appear: toView, appearViews: appearViews),
				uniquingKeysWith: { $1.combined(with: $0) }
			)
		}
		
		properties[inView] = delegate.containerModifier
		
		let forAppear = appearViews.compactMap { view in
			properties[view].map { (view, $0.appear, $0.current(for: view, .present)) }
		}
		let forDisappear = disappearViews.compactMap { view in
			properties[view].map { (view, $0.disappear, $0.current(for: view, .present)) }
		}
		
		let containerCurrent: ((UIView) -> Void, (UIView) -> Void) = (
			delegate.containerModifier.current(for: inView, .present),
			delegate.containerModifier.current(for: inView, .dismiss)
		)
		let containerModifier = delegate.containerModifier
			
		var main: [VDAnimationProtocol] = []
		
		if !properties.isEmpty {
			main.append(
				Animate {[transitionType, weak inView] in
					forAppear.forEach {
						$0.2($0.0)
					}
					forDisappear.forEach {
						$0.1($0.0)
					}
					if let inView = inView {
						(transitionType.show ? containerModifier.appear : containerCurrent.1)(inView)
					}
				}
			)
		}
		
		let duration = transitionDuration(using: transitionContext)
		
		let animation: VDAnimationProtocol
		
		switch (main.isEmpty, self.animation) {
		case (true, nil):
			return nil
		case (true, .some(let second)):
			let context = Context(fromVC: fromVc, toVC: toVc, type: transitionType, container: inView)
			animation = second(context)
		case (false, nil):
			animation = main.count == 1 ? main[0] : Parallel(main)
		case (false, .some(let second)):
			let context = Context(fromVC: fromVc, toVC: toVc, type: transitionType, container: inView)
			let additional = second(context)
			animation = Parallel(main + [additional])
		}
		
		animator = animation.duration(duration).curve(curve).delegate()
		
		forAppear.forEach {
			$0.1($0.0)
		}
		(transitionType.show ? containerCurrent.0 : containerModifier.disappear)(inView)
		
		completion = {[transitionType] in
			if $0 {
				if transitionType.show {
					forDisappear.forEach {
						$0.2($0.0)
					}
				} else {
					changing.removeFromSuperview()
				}
			} else {
				(forAppear + forDisappear).forEach {
					$0.2($0.0)
				}
			}
			transitionContext.completeTransition($0)
		}
		return animator
	}
	
	private func properties(pares: [UIView: UIView], disappear: UIView, disappearViews: [UIView], appear: UIView, appearViews: [UIView]) -> [UIView: Properties] {
		
		var transforms: [UIView: CGAffineTransform] = [:]
		self.transforms(disappear: disappear, pares: pares, transforms: &transforms)
		var properties: [UIView: Properties] = [:]
		
		(appearViews + disappearViews).forEach {
			if let transform = transforms[$0] {
				properties[$0] = .init(\.transform) { _, current in current.added(transform) }
			}
		}
		
		if !properties.isEmpty || self.animation == nil {
			let changing = transitionType.show ? appear : disappear
			properties[changing, default: .identity].combine(with: .opacity)
		}
		
		pares.forEach {
			set(\.layer.cornerRadius, disappear: $0.key, appear: $0.value, properties: &properties)
			set(\.backgroundColor, disappear: $0.key, appear: $0.value, properties: &properties)
		}
		
		return properties
	}
	
	func set<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<UIView, T>, disappear: UIView, appear: UIView, properties: inout [UIView: Properties]) {
		guard disappear[keyPath: keyPath] != appear[keyPath: keyPath] else {
			return
		}
		properties[disappear, default: .identity].combine(with: .init(keyPath, value: appear[keyPath: keyPath]))
		properties[appear, default: .identity].combine(with: .init(keyPath, value: disappear[keyPath: keyPath]))
	}
	
	private func transforms(disappear: UIView, pares: [UIView: UIView], transforms: inout [UIView: CGAffineTransform]) {
		if let appear = pares[disappear] {
			let tr = transform(disappear: disappear, appear: appear)
			zip([tr.1, tr.0], [appear, disappear]).forEach {
				var result = $0.0
				if let parent = $0.1.superview, let parentTransform = transforms[parent] {
					result = result.concatenating(parentTransform.inverted())
				}
				transforms[$0.1] = result
			}
		}
		for view in disappear.subviews {
			self.transforms(disappear: view, pares: pares, transforms: &transforms)
		}
	}
	
	private func transform(disappear: UIView, appear: UIView) -> (CGAffineTransform, CGAffineTransform) {
		let appearFrame = appear.convert(appear.bounds, to: appear.window)
		let disappearFrame = disappear.convert(disappear.bounds, to: disappear.window)
		
		let scale = CGSize(
			width: appearFrame.width / (disappearFrame.width == 0 ? 1 : disappearFrame.width),
			height: appearFrame.height / (disappearFrame.height == 0 ? 1 : disappearFrame.height)
		)
		let offset = CGPoint(
			x: (appearFrame.midX - disappearFrame.midX),
			y: (appearFrame.midY - disappearFrame.midY)
		)
		#warning("anchorPoint")
		return (
			CGAffineTransform.identity
				.scaledBy(x: scale.width, y: scale.height)
				.added(.translate(offset.x, offset.y)),
			
			CGAffineTransform.identity
				.scaledBy(x: 1 / (scale.width == 0 ? 1 : scale.width), y: 1 / (scale.height == 0 ? 1 : scale.height))
				.added(.translate(-offset.x, -offset.y))
		)
	}
	
	private func prepareInteractive(context: UIViewControllerContextTransitioning) {
		guard let interactive = interactivity, let delegate = self.delegate else { return }
		switch transitionType {
		case .present:
			guard let vc = context.viewController(forKey: .to) else { return }
			delegate.interactiveTransitioning = interactive.appear(context.containerView, vc, delegate, self)
		case .dismiss:
			guard let vc = context.viewController(forKey: .from) else { return }
			delegate.interactiveTransitioning = interactive.disappear(context.containerView, vc, delegate, self)
		case .pop:
			break
		case .push:
			break
		case .set:
			break
		}
	}
	
	public typealias Properties = VDTransition<UIView>
	
	public struct Context {
		public let fromVC: UIViewController
		public let toVC: UIViewController
		public let type: TransitionType
		public let container: UIView
	}
}
