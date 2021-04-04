//
//  VDTransition.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

public struct VDTransition<Content, Result> {
	public var appear: (Content) -> Result
	public var disappear: (Content) -> Result
	public var final: (Content) -> Void
	
	public subscript(_ type: TransitionType) -> (Content) -> Result {
		type.show ? appear : disappear
	}
	
	public init(_ change: @escaping (Content) -> Result, final: @escaping (Content) -> Void) {
		self.appear = change
		self.disappear = change
		self.final = final
	}
	
	public init(appear: @escaping (Content) -> Result, disappear: @escaping (Content) -> Result, final: @escaping (Content) -> Void) {
		self.appear = appear
		self.disappear = disappear
		self.final = final
	}
}

extension VDTransition {
	public static func asymmetric(appear: VDTransition, disappear: VDTransition) -> VDTransition {
		VDTransition(appear: appear.appear, disappear: disappear.disappear) {
			appear.final($0)
			disappear.final($0)
		}
	}
}

extension VDTransition {
	public func combined(with other: VDTransition, result: @escaping (Result, Result) -> Result) -> VDTransition {
		VDTransition(
			appear: {
				result(
					self.appear($0),
					other.appear($0)
				)
			},
			disappear: {
				result(
					self.disappear($0),
					other.disappear($0)
				)
			},
			final: {
				self.final($0)
				other.final($0)
			}
		)
	}
}

extension VDTransition where Result == Void {
	public func combined(with other: VDTransition) -> VDTransition {
		combined(with: other, result: {_, _ in })
	}
}

extension VDTransition where Result == VDAnimationProtocol {
	
	public init(_ animation: @escaping (Content) -> VDAnimationProtocol) {
		self.init(appear: animation) {
			animation($0).reversed()
		} final: {_ in }
	}
}

extension VDTransition where Result == Void {
	
	public static var identity: VDTransition { .init(appear: {_ in}, disappear: {_ in}, final: {_ in }) }
	
	public static func property<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, value: T) -> VDTransition {
		.property(keyPath, value: {_ in value })
	}
	
	public static func property<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, value: @escaping (Content) -> T) -> VDTransition {
		let owner = Value<T>()
		return VDTransition {
			owner.value = $0[keyPath: keyPath]
			$0[keyPath: keyPath] = value($0)
		} final: {
			$0[keyPath: keyPath] = owner.value ?? $0[keyPath: keyPath]
		}
	}
}

extension VDTransition where Content: UIView, Result == Void {
	
	public static var opacity: VDTransition {
		opacity(0)
	}
	
	public var opacity: VDTransition {
		combined(with: .opacity)
	}
	
	public static func opacity(_ k: CGFloat) -> VDTransition {
		property(\.alpha) { $0.alpha * k }
	}
	
	public func opacity(_ k: CGFloat) -> VDTransition {
		combined(with: .opacity(k))
	}
	
	public static var scale: VDTransition {
		scale(0.0001)
	}
	
	public var scale: VDTransition {
		combined(with: .scale)
	}
	
	public static func scale(_ k: Double) -> VDTransition {
		transform(.scale(k))
	}
	
	public func scale(_ k: Double) -> VDTransition {
		transform(.scale(k))
	}
	
	public static func transform(_ transform: CGAffineTransform) -> VDTransition {
		property(\.transform) { $0.transform.added(transform) }
	}
	
	public func transform(_ transform: CGAffineTransform) -> VDTransition {
		combined(with: .transform(transform))
	}
	
	public static func transform3D(_ transform: CATransform3D) -> VDTransition {
		property(\.layer.transform, value: transform)
	}

	public func transform3D(_ transform: CATransform3D) -> VDTransition {
		combined(with: .transform3D(transform))
	}
	
	public static func background(_ color: UIColor) -> VDTransition {
		property(\.backgroundColor, value: color)
	}
	
	public func background(_ color: UIColor) -> VDTransition {
		combined(with: .background(color))
	}
	
	public static func edge(_ edge: Edges, offset: CGFloat = 0) -> VDTransition {
		property(\.transform) {
			let frame = $0.convert($0.bounds, to: $0.window)
			let windowSize = $0.window?.frame.size ?? UIScreen.main.bounds.size
			switch edge {
			case .top:
				return $0.transform.added(.translate(0, -(frame.minY + frame.height + offset)))
			case .leading:
				return $0.transform.added(.translate(-(frame.minX + frame.width + offset), 0))
			case .bottom:
				return $0.transform.added(.translate(0, windowSize.height - frame.minY + offset))
			case .trailing:
				return $0.transform.added(.translate(windowSize.width - frame.minX + offset, 0))
			}
		}
	}
	
	public func edge(_ edge: Edges, offset: CGFloat = 0) -> VDTransition {
		combined(with: .edge(edge, offset: offset))
	}
	
	public static func offset(_ point: CGPoint) -> VDTransition {
		property(\.transform) {
			return $0.transform.added(.translate(point.x, point.y))
		}
	}
	
	public func offset(_ point: CGPoint) -> VDTransition {
		combined(with: .offset(point))
	}
	
	public static func offset(x: CGFloat = 0, y: CGFloat = 0) -> VDTransition {
		offset(CGPoint(x: x, y: y))
	}
	
	public func offset(x: CGFloat = 0, y: CGFloat = 0) -> VDTransition {
		combined(with: .offset(x: x, y: y))
	}
	
	public static func slide(from: Edges, to: Edges) -> VDTransition {
		asymmetric(
			appear: .edge(from),
			disappear: .edge(to)
		)
	}
	
	public func slide(from: Edges, to: Edges) -> VDTransition {
		combined(with: .slide(from: from, to: to))
	}
	
	public static var slide: VDTransition {
		slide(from: .leading, to: .trailing)
	}
	
	public var slide: VDTransition {
		combined(with: .slide)
	}
}

private final class Value<T> {
	var value: T?
}
