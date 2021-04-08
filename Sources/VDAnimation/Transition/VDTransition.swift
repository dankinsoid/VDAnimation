//
//  VDTransition.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

public struct VDTransition<Content> {
	private let appearKps: [KP]
	private let disappearKps: [KP]
	
	public var appear: (Content) -> Void {
		{[appearKps] content in
			appearKps.forEach { $0.set(for: content) }
		}
	}
	
	public var disappear: (Content) -> Void {
		{[disappearKps] content in
			disappearKps.forEach { $0.set(for: content) }
		}
	}
	
	private init(appear: [KP], disappear: [KP]) {
		self.appearKps = appear
		self.disappearKps = disappear
	}
	
	public init<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, value: @escaping (Content, T) -> T) {
		appearKps = [KP(keyPath, value: value)]
		disappearKps = [KP(keyPath, value: value)]
	}
	
	public init<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, value: T) {
		self.init(keyPath, value: {_, _ in value })
	}
	
	public init<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, appear: T, disappear: T) {
		self.appearKps = [KP(keyPath, value: {_, _ in appear })]
		self.disappearKps = [KP(keyPath, value: {_, _ in disappear })]
	}
	
	public func current(for content: Content, _ type: TransitionType) -> (Content) -> Void {
		let kp = type.show ? appearKps : disappearKps
		let current = kp.map { ($0, content[keyPath: $0.get]) }
		return { content in
			current.forEach {
				$0.0.set(content, $0.1)
			}
		}
	}
	
	private struct KP {
		let get: PartialKeyPath<Content>
		let set: (Content, Any) -> Void
		private let value: (Content, Any) -> Any
		
		init<T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, value: @escaping (Content, T) -> T) {
			get = keyPath
			set = {
				guard let value = $1 as? T else { return }
				$0[keyPath: keyPath] = value
			}
			self.value = {
				guard let v = $1 as? T else { return $1 }
				return value($0, v)
			}
		}
		
		private init(get: PartialKeyPath<Content>, set: @escaping (Content, Any) -> Void, value: @escaping (Content, Any) -> Any) {
			self.get = get
			self.set = set
			self.value = value
		}
		
		func set(for content: Content) {
			set(content, value(content, content[keyPath: get]))
		}
		
		func merge(with kp: KP) -> KP? {
			guard get == kp.get else { return nil }
			return KP(get: get, set: set) {[value] content, current in
				kp.value(content, value(content, current))
			}
		}
	}
}

extension VDTransition {
	
	public static var identity: VDTransition { .init(appear: [], disappear: []) }
	
	public static func asymmetric(appear: VDTransition, disappear: VDTransition) -> VDTransition {
		VDTransition(appear: appear.appearKps, disappear: disappear.disappearKps)
	}
	
	public func combined(with other: VDTransition) -> VDTransition {
		VDTransition(
			appear: merge(appearKps, other.appearKps),
			disappear: merge(disappearKps, other.disappearKps)
		)
	}
	
	public mutating func combine(with other: VDTransition) {
		self = combined(with: other)
	}
	
	private func merge(_ lhs: [KP], _ rhs: [KP]) -> [KP] {
		(lhs + rhs).reduce([]) {
			var result = $0
			for i in result.indices {
				if let merged = result[i].merge(with: $1) {
					result[i] = merged
					return result
				}
			}
			result.append($1)
			return result
		}
	}
}

extension VDTransition where Content: UIView {
	
	public static var opacity: VDTransition {
		opacity(0)
	}
	
	public var opacity: VDTransition {
		combined(with: .opacity)
	}
	
	public static func opacity(_ k: CGFloat) -> VDTransition {
		.init(\.alpha) { _, alpha in alpha * k }
	}
	
	public func opacity(_ k: CGFloat) -> VDTransition {
		combined(with: .opacity(k))
	}
	
	public static var scale: VDTransition {
		scale(0.005)
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
		.init(\.transform) { $0.addTransform(transform, current: $1) }
	}
	
	public func transform(_ transform: CGAffineTransform) -> VDTransition {
		combined(with: .transform(transform))
	}
	
	public static func transform3D(_ transform: CATransform3D) -> VDTransition {
		.init(\.layer.transform) {
			$0.layer.addTransform(transform, current: $1)
		}
	}

	public func transform3D(_ transform: CATransform3D) -> VDTransition {
		combined(with: .transform3D(transform))
	}
	
	public static func background(_ color: UIColor) -> VDTransition {
		.init(\.backgroundColor, value: color)
	}
	
	public func background(_ color: UIColor) -> VDTransition {
		combined(with: .background(color))
	}
	
	public static func edge(_ edge: Edges, offset: CGFloat = 0, in view: UIView? = nil) -> VDTransition {
		.init(\.transform) {
			let frame = $0.convert($1 == $0.transform ? $0.bounds : $0.bounds.applying($1), to: view)
			let windowSize = (view ?? $0.window)?.frame.size ?? UIScreen.main.bounds.size
			switch edge {
			case .top:
				return $0.offsetTransform(CGPoint(x: 0, y: -(frame.maxY - offset)), current: $1)
			case .leading:
				return $0.offsetTransform(CGPoint(x: -(frame.maxX - offset), y: 0), current: $1)
			case .bottom:
				return $0.offsetTransform(CGPoint(x: 0, y: windowSize.height - frame.minY - offset), current: $1)
			case .trailing:
				return $0.offsetTransform(CGPoint(x: windowSize.width - frame.minX - offset, y: 0), current: $1)
			}
		}
	}
	
	public func edge(_ edge: Edges, offset: CGFloat = 0, in view: UIView? = nil) -> VDTransition {
		combined(with: .edge(edge, offset: offset, in: view))
	}
	
	public static func offset(_ point: CGPoint) -> VDTransition {
		transform(.translate(point.x, point.y))
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
	
	public static func slide(from: Edges = .leading, to: Edges = .trailing, in view: UIView? = nil) -> VDTransition {
		asymmetric(
			appear: .edge(from, in: view),
			disappear: .edge(to, in: view)
		)
	}
	
	public func slide(from: Edges = .leading, to: Edges = .trailing, in view: UIView? = nil) -> VDTransition {
		combined(with: .slide(from: from, to: to, in: view))
	}
	
	public static var slide: VDTransition {
		slide()
	}
	
	public var slide: VDTransition {
		combined(with: .slide)
	}
	
	public static func rotate(_ angle: CGFloat) -> VDTransition {
		transform(.rotate(angle))
	}
	
	public func rotate(_ angle: CGFloat) -> VDTransition {
		transform(.rotate(angle))
	}
	
	public static func rotate(_ angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) -> VDTransition {
		transform3D(.rotate(angle, x: x, y: y, z: z))
	}
	
	public func rotate(_ angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) -> VDTransition {
		transform3D(.rotate(angle, x: x, y: y, z: z))
	}
	
	public static func corner(radius: CGFloat) -> VDTransition {
		.init(\.layer.cornerRadius, value: radius)
	}
	
	public func corner(radius: CGFloat) -> VDTransition {
		combined(with: .corner(radius: radius))
	}
}

private extension UIView {
	func offsetTransform(_ point: CGPoint, current: CGAffineTransform) -> CGAffineTransform {
		addTransform(.translate(point.x, point.y), current: current)
	}
	
	func addTransform(_ dif: CGAffineTransform, current: CGAffineTransform) -> CGAffineTransform {
		let k = superview?.transformInWindow ?? .identity
		var result = current.added(dif)
		result.ty = current.ty + dif.ty / k.d
		result.tx = current.tx + dif.tx / k.a
		return result
	}
}

private extension CALayer {
	
	func addTransform(_ dif: CATransform3D, current: CATransform3D) -> CATransform3D {
		let k = superlayer?.transformInWindow ?? .identity
		var result = current.concatenating(dif)
		result.m41 = transform.m41 + dif.m41 / sqrt(pow(k.m11, 2) + pow(k.m12, 2) + pow(k.m13, 2))
		result.m42 = transform.m42 + dif.m42 / sqrt(pow(k.m21, 2) + pow(k.m22, 2) + pow(k.m33, 2))
		result.m43 = transform.m43 + dif.m43 / sqrt(pow(k.m31, 2) + pow(k.m32, 2) + pow(k.m33, 2))
		return result
	}
}
