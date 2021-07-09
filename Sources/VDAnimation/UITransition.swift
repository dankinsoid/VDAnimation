////
////  File.swift
////
////
////  Created by Данил Войдилов on 30.06.2021.
////
//
//import UIKit
//
//struct UITransition {
//
//	private let fromView: UIView
//	private let toView: UIView
//	private let inView: UIView
//	private let show: Bool
//	private let containerModifier: VDTransition<UIView>
//	private let applyModifierOnBothView: Bool
//	private let modifier: VDTransition<UIView>?
//	private let additionalModifiers: [UIView: VDTransition<UIView>]
//
//
//
////	if let modifier = stableVc.transition.modifier {
////		properties[stable, default: .identity].combine(with: modifier)
////	}
////	if let modifier = changingVc.transition.modifier {
////		properties[changing, default: .identity].combine(with: modifier)
////	}
//
//	func prepareAnimation(options: AnimationOptions) -> AnimationDelegateProtocol {
//		let changing = show ? toView : fromView
//		let stable = show ? fromView : toView
//
//		if stable.window == nil {
//			inView.addSubview(stable)
//			stable.frame = inView.bounds
//			stable.layoutIfNeeded()
//		}
//		inView.addSubview(changing)
//		changing.frame = inView.bounds
//		changing.layoutIfNeeded()
//
//		delegate.prepare?(context)
//
//		inView.layoutIfNeeded()
//
////		prepareInteractive()
//
//
//		let containerViews: [UIView] = [inView] + inView.subviews
//			.filter({ $0 != toView && $0 != fromView })
//			.map { [$0] + $0.allSubviews() }
//			.joined()
//		let appearViews = [toView] + toView.allSubviews() + (show ? [] : containerViews)
//		let disappearViews = [fromView] + fromView.allSubviews() + (show ? containerViews : [])
//
//		let appearIds = appearViews.mapDictionary { ($0.transition.id, $0) }
//		let pares = disappearViews.mapDictionary { ($0, $0.transition.id) }.compactMapValues { appearIds[$0] }
//
//		inView.transition.modifier = containerModifier
//
//		var properties: [UIView: VDTransition<UIView>] = (appearViews + disappearViews).compactMapDictionary { view in
//			view.transition.modifier.map { (view, $0) }
//		}
//		properties.merge(additionalModifiers, uniquingKeysWith: { $1.combined(with: $0) })
//
//
//		if applyModifierOnBothView {
//			if let modifier = modifier {
//				properties[toView, default: .identity].combine(with: show ? modifier.inverted : modifier)
//				properties[fromView, default: .identity].combine(with: show ? modifier.inverted : modifier)
//			}
//		} else {
//			if let modifier = modifier {
//				properties[changing, default: .identity].combine(with: modifier)
//			}
//		}
//
//		if !pares.isEmpty {
//			properties.merge(
//				self.properties(
//					pares: pares,
//					disappear: fromView,
//					disappearViews: disappearViews,
//					appear: toView,
//					appearViews: appearViews
//				),
//				uniquingKeysWith: { $1.combined(with: $0) }
//			)
//		}
//
//		let forAppear = appearViews.compactMap { view in
//			properties[view].map { (view, delegate.disappearStates[view] == nil ? $0.appear : $0.current(for: view, .present), $0.current(for: view, .present)) }
//		}
//		let forDisappear = disappearViews.compactMap { view in
//			properties[view].map { (view, $0.disappear, $0.current(for: view, .present)) }
//		}
//
//		let animator = UIViewAnimate {[weak self] in
//			forAppear.forEach {
//				self?.delegate?.disappearStates[$0.0]?($0.0) ?? $0.2($0.0)
//			}
//			forDisappear.forEach {
//				$0.1($0.0)
//			}
//			self?.delegate?.inAnimation?(context)
//		}.delegate(with: options)
//
//
//		forAppear.forEach {
//			$0.1($0.0)
//		}
//
//		animator.add {[weak self, transitionType] in
//			if $0 {
//				if show {
//					if self?.delegate?.restoreDisappearedViews == true {
//						self?.delegate?.disappearStates = [:]
//						forDisappear.forEach {
//							$0.2($0.0)
//						}
//					} else {
//						self?.delegate?.disappearStates = forDisappear.mapDictionary { ($0.0, $0.2) }
//					}
//				} else {
//					self?.delegate?.disappearStates = [:]
//					changing.removeFromSuperview()
//				}
//			} else {
//				(forAppear + forDisappear).forEach {
//					$0.2($0.0)
//				}
//			}
//			self?.delegate?.completion?(context, $0)
//			transitionContext.completeTransition($0)
//		}
//
//		return animator
//	}
//
//	private func properties(pares: [UIView: UIView], disappear: UIView, disappearViews: [UIView], appear: UIView, appearViews: [UIView]) -> [UIView: VDTransition<UIView>] {
//
//		var transforms: [UIView: CGAffineTransform] = [:]
//		self.transforms(disappear: disappear, pares: pares, transforms: &transforms)
//		var properties: [UIView: VDTransition<UIView>] = [:]
//
//		(appearViews + disappearViews).forEach {
//			if let transform = transforms[$0] {
//				properties[$0] = .init(\.transform) { _, current in current.added(transform) }
//			}
//		}
//
//		if !properties.isEmpty {
//			let changing = show ? appear : disappear
//			properties[changing, default: .identity].combine(with: .opacity)
//		}
//
//		pares.forEach {
//			set(\.layer.cornerRadius, disappear: $0.key, appear: $0.value, properties: &properties)
//			set(\.backgroundColor, disappear: $0.key, appear: $0.value, properties: &properties)
//		}
//
//		return properties
//	}
//
//	func set<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<UIView, T>, disappear: UIView, appear: UIView, properties: inout [UIView: VDTransition<UIView>]) {
//		guard disappear[keyPath: keyPath] != appear[keyPath: keyPath] else {
//			return
//		}
//		properties[disappear, default: .identity].combine(with: .init(keyPath, value: appear[keyPath: keyPath]))
//		properties[appear, default: .identity].combine(with: .init(keyPath, value: disappear[keyPath: keyPath]))
//	}
//
//	private func transforms(disappear: UIView, pares: [UIView: UIView], transforms: inout [UIView: CGAffineTransform]) {
//		if let appear = pares[disappear] {
//			let tr = transform(disappear: disappear, appear: appear)
//			zip([tr.1, tr.0], [appear, disappear]).forEach {
//				var result = $0.0
//				if let parent = $0.1.superview, let parentTransform = transforms[parent] {
//					result = result.concatenating(parentTransform.inverted())
//				}
//				transforms[$0.1] = result
//			}
//		}
//		for view in disappear.subviews {
//			self.transforms(disappear: view, pares: pares, transforms: &transforms)
//		}
//	}
//
//	private func transform(disappear: UIView, appear: UIView) -> (CGAffineTransform, CGAffineTransform) {
//		let appearFrame = appear.convert(appear.bounds, to: appear.window)
//		let disappearFrame = disappear.convert(disappear.bounds, to: disappear.window)
//
//		let scale = CGSize(
//			width: appearFrame.width / (disappearFrame.width == 0 ? 1 : disappearFrame.width),
//			height: appearFrame.height / (disappearFrame.height == 0 ? 1 : disappearFrame.height)
//		)
//		let offset = CGPoint(
//			x: (appearFrame.midX - disappearFrame.midX),
//			y: (appearFrame.midY - disappearFrame.midY)
//		)
//		//#warning("anchorPoint")
//		return (
//			CGAffineTransform.identity
//				.scaledBy(x: scale.width, y: scale.height)
//				.added(.translate(offset.x, offset.y)),
//
//			CGAffineTransform.identity
//				.scaledBy(x: 1 / (scale.width == 0 ? 1 : scale.width), y: 1 / (scale.height == 0 ? 1 : scale.height))
//				.added(.translate(-offset.x, -offset.y))
//		)
//	}
//}
