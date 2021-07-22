//
//  VDAnimatedTransitioning.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import VDKit

open class VDAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning {
	public typealias Context = VDTransitionContext
	
	public var transitionType: TransitionType
	private(set) var animator: AnimationDelegateProtocol?
	private var completion: ((Bool) -> Void)?
	private(set) public weak var delegate: VDTransitioningDelegate?
	public weak var presentingViewController: UIViewController?
	
	public var duration: TimeInterval { delegate?.duration ?? 0 }
	public var curve: BezierCurve { delegate?.curve ?? .linear }
	public var parallelAnimation: TransitionParallelAnimation? { delegate?.parallelAnimation }
	public var interactivity: TransitionInteractivity? { delegate?.interactivity }
	
	public init(_ transitionType: TransitionType, delegate: VDTransitioningDelegate, presenting: UIViewController?) {
		self.transitionType = transitionType
		self.delegate = delegate
		presentingViewController = presenting
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
		animation.play()
	}
	
	open func animationCompleted(_ transitionCompleted: Bool) {
		animator = nil
		completion?(transitionCompleted)
		completion = nil
		delegate?.currentTransitioning = nil
	}
	
	open func prepareAnimation(for transitionContext: UIViewControllerContextTransitioning) -> AnimationDelegateProtocol? {
		if let result = animator {
			return result
		}
		guard let toVc = transitionContext.viewController(forKey: .to), let fromVc = transitionContext.viewController(forKey: .from), let delegate = self.delegate else {
			return nil
		}
		let inView = transitionContext.containerView
		inView.backgroundColor = .clear
		toVc.loadViewIfNeeded()
		fromVc.loadViewIfNeeded()
		let toView: UIView = toVc.view
		let fromView: UIView = fromVc.view
		
		let context = Context(fromVC: fromVc, toVC: toVc, type: transitionType, container: inView)
		
		let stableVc = transitionType.show ? fromVc : toVc
		let changingVc = transitionType.show ? toVc : fromVc
		let changing: UIView = changingVc.view
		let stable: UIView = stableVc.view
		if stable.window == nil {
			inView.addSubview(stable)
			stable.frame = inView.bounds
			stable.layoutIfNeeded()
		}
		inView.addSubview(changing)
		changing.frame = inView.bounds
		changing.layoutIfNeeded()
		
		delegate.prepare?(context)
		inView.layoutIfNeeded()
		
		prepareInteractive(context: transitionContext)
		
		let containerViews: [UIView] = [inView] + inView.subviews
			.filter({ $0 != toView && $0 != fromView })
			.map { [$0] + $0.allSubviews() }
			.joined()
		
		let appearViews = [toView] + toView.allSubviews() + (transitionType.show ? [] : containerViews)
		let disappearViews = [fromView] + fromView.allSubviews() + (transitionType.show ? containerViews : [])
		
		let appearIds = appearViews.mapDictionary { ($0.transition.id, $0) }
		let pares = disappearViews.mapDictionary { ($0, $0.transition.id) }.compactMapValues { appearIds[$0] }
		inView.transition.modifier = delegate.containerModifier
		
		var properties: [UIView: Properties] = (appearViews + disappearViews).compactMapDictionary { view in
			view.transition.modifier.map { (view, $0) }
		}
		if let modifier = stableVc.transition.modifier {
			properties[stable, default: .identity].combine(with: modifier)
		}
		if let modifier = changingVc.transition.modifier {
			properties[changing, default: .identity].combine(with: modifier)
		}
		if delegate.applyModifierOnBothVC {
			if let modifier = delegate.modifier {
				properties[toView, default: .identity].combine(with: transitionType.show ? modifier.inverted : modifier)
			}
			if let modifier = delegate.modifier {
				properties[fromView, default: .identity].combine(with: transitionType.show ? modifier.inverted : modifier)
			}
		} else {
			if let modifier = delegate.modifier {
				properties[changing, default: .identity].combine(with: modifier)
			}
		}
		
		if !pares.isEmpty {
			properties.merge(
				self.properties(
					pares: pares,
					disappear: fromView,
					disappearViews: disappearViews,
					appear: toView,
					appearViews: appearViews
				),
				uniquingKeysWith: { $1.combined(with: $0) }
			)
		}
		
		let forAppear = appearViews.compactMap { view in
			properties[view].map { (view, delegate.disappearStates[view] == nil ? $0.appear : $0.current(for: view, .present), $0.current(for: view, .present)) }
		}
		let forDisappear = disappearViews.compactMap { view in
			properties[view].map { (view, $0.disappear, $0.current(for: view, .present)) }
		}
			
		var main: [VDAnimationProtocol] = []
		
		if !properties.isEmpty || delegate.inAnimation != nil {
			main.append(
				UIViewAnimate {[weak self] in
					forAppear.forEach {
						self?.delegate?.disappearStates[$0.0]?($0.0) ?? $0.2($0.0)
					}
					forDisappear.forEach {
						$0.1($0.0)
					}
					self?.delegate?.inAnimation?(context)
				}
			)
		}
		
		let duration = transitionDuration(using: transitionContext)
		
		let animation: VDAnimationProtocol
		
		switch (main.isEmpty, self.parallelAnimation) {
		case (true, nil):
			return nil
		case (true, .some(let second)):
			animation = second.animation(context)
		case (false, nil):
			animation = main.count == 1 ? main[0] : Parallel(main)
		case (false, .some(let second)):
			let additional = second.animation(context)
			animation = Parallel(main + [additional])
		}
		
		animator = animation.duration(duration).curve(curve).delegate()
		
		forAppear.forEach {
			$0.1($0.0)
		}
		
		completion = {[weak self, transitionType] in
			if $0 {
				if transitionType.show {
					if self?.delegate?.restoreDisappearedViews == true {
						self?.delegate?.disappearStates = [:]
						forDisappear.forEach {
							$0.2($0.0)
						}
					} else {
						let forStates = forDisappear.filter { $0.0 !== inView }
						self?.delegate?.disappearStates = forStates.mapDictionary { ($0.0, $0.2) }
					}
				} else {
					self?.delegate?.disappearStates = [:]
					changing.removeFromSuperview()
				}
			} else {
				(forAppear + forDisappear).filter { $0.0 !== inView }.forEach {
					$0.2($0.0)
				}
			}
			self?.delegate?.completion?(context, $0)
			transitionContext.completeTransition($0)
		}
		
		animator?.add {[weak self] in
			self?.animationCompleted($0)
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
		
		if !properties.isEmpty || self.parallelAnimation == nil {
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
		//#warning("anchorPoint")
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
		if transitionType == .present || transitionType == .dismiss {
			delegate?.configureInteractive(in: context.containerView)
		}
	}
	
	open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		prepareAnimation(for: transitionContext)?.play()
	}
	
//	open func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
//		ImplicitlyAnimating(prepareAnimation(for: transitionContext) ?? Instant{}.delegate())
//	}
	
	public typealias Properties = VDTransition<UIView>

}
