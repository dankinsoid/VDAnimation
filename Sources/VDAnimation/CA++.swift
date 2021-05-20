//
//  CA++.swift
//  CA
//
//  Created by Daniil on 10.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit

extension CGAffineTransform {
	
	public var transform3d: CATransform3D {
		CATransform3DMakeAffineTransform(self)
	}
	
	public var offset: CGPoint {
		get { CGPoint(x: tx, y: ty) }
		set {
			tx = newValue.x
			ty = newValue.y
		}
	}
	
	public var scale: CGSize {
		CGSize(
			width: c == 0 ? a : (a > 0 ? 1 : -1) * sqrt(pow(a, 2) + pow(c, 2)),
			height: b == 0 ? d : (d > 0 ? 1 : -1) * sqrt(pow(b, 2) + pow(d, 2))
		)
	}
	
	public var angle: CGFloat {
		atan2(b, a)
	}
	
	public func added(_ other: CGAffineTransform) -> CGAffineTransform {
		let scale1 = scale
		let scale2 = other.scale
		var result = CGAffineTransform.identity
			.rotated(by: angle + other.angle)
			.scaledBy(x: scale1.width * scale2.width, y: scale1.height * scale2.height)
		result.tx = tx + other.tx
		result.ty = ty + other.ty
		return result
	}
}

extension CATransform3D {
	
	public var affine: CGAffineTransform {
		CATransform3DGetAffineTransform(self)
	}
	
	public func inverted() -> CATransform3D {
		CATransform3DInvert(self)
	}
	
	public func concatenating(_ other: CATransform3D) -> CATransform3D {
		CATransform3DConcat(self, other)
	}
	
	public func added(_ other: CATransform3D) -> CATransform3D {
		let new = CATransform3DConcat(self, other)
		return CATransform3D(
			m11: new.m11, m12: new.m12, m13: new.m13, m14: new.m14,
			m21: new.m21, m22: new.m22, m23: new.m23, m24: new.m24,
			m31: new.m31, m32: new.m32, m33: new.m33, m34: new.m34,
			m41: m41 + other.m41, m42: m42 + other.m42, m43: m43 + other.m43, m44: new.m44
		)
	}
}

extension UIView {
	public var transformInWindow: CGAffineTransform {
		([self] + superviews).reversed().reduce(.identity) {
			$0.concatenating($1.transform)
		}
	}
}


extension CALayer {
	public var superlayers: [CALayer] {
		superlayer.map { [$0] + $0.superlayers } ?? []
	}
	
	public var transformInWindow: CATransform3D {
		([self] + superlayers).reversed().reduce(.identity) { $0.concatenating($1.transform)
		}
	}
}

extension Edges {
	public static var left: Edges { .leading }
	public static var right: Edges { .trailing }
	
	public var axe: NSLayoutConstraint.Axis {
		switch self {
		case .bottom, .top: return .vertical
		case .leading, .trailing: return .horizontal
		}
	}
	
	public var opposite: Edges {
		switch self {
		case .leading: return .trailing
		case .bottom: return .top
		case .top: return .bottom
		case .trailing: return .leading
		}
	}
}

extension UIRectEdge {
	public init(_ edge: Edges) {
		switch edge {
		case .leading: 	self = .left
		case .bottom: 	self = .bottom
		case .top: 			self = .top
		case .trailing: self = .right
		}
	}
}

extension UIEdgeInsets {
	public subscript(_ edge: Edges) -> CGFloat {
		switch edge {
		case .leading: 	return right
		case .bottom: 	return top
		case .top: 			return bottom
		case .trailing: return left
		}
	}
}

extension CACornerMask {
	public static func edge(_ edge: Edges) -> CACornerMask {
		switch edge {
		case .leading: 	return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
		case .bottom: 	return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
		case .top: 			return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		case .trailing: return [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
		}
	}
}

extension UIScreen {
	/// The corner radius of the display. Uses a private property of `UIScreen`,
	/// and may report 0 if the API changes.
	public var cornerRadius: CGFloat {
		guard let cornerRadius = self.value(forKey: "_displayCornerRadius") as? CGFloat else {
			return 0
		}
		return cornerRadius
	}
}

//
//extension CALayer {
//
//    func allSublayers() -> [CALayer] {
//        (sublayers ?? []) + (sublayers?.reduce([], { $0 + $1.allSublayers() }) ?? [])
//    }
//
//    func allProperties() -> [String: Any] {
//        Dictionary(uniqueKeysWithValues: CALayer.allKeys.map { ($0, value(forKey: $0)) })
//    }
//
//    static var allKeys: [String] = {
//        var count: UInt32 = 0
//        guard let properties = class_copyPropertyList(CALayer.self, &count) else { return [] }
//        var rv: [String] = []
//        for i in 0..<Int(count) {
//            let property = properties[i]
//            let name = String(utf8String: property_getName(property)) ?? ""
//            rv.append(name)
//        }
//        free(properties)
//        return rv
//    }()
//
//    func allPropertyNames() -> [String] {
//        var count: UInt32 = 0
//        guard let properties = class_copyPropertyList(type(of: self), &count) else { return [] }
//        var rv: [String] = []
//        for i in 0..<Int(count) {
//            let property = properties[i]
//            let name = String(utf8String: property_getName(property)) ?? ""
//            rv.append(name)
//        }
//        free(properties)
//        return rv
//    }
//
//    static func ff(_ action: () -> Void) {
//        guard let window = UIApplication.shared.keyWindow else { return }
//        let all = [window.layer] + window.layer.allSublayers()
//        print(all.count)
//        let before = Dictionary(uniqueKeysWithValues: all.map { ($0, $0.allProperties()) })
//        action()
//        let after = Dictionary(uniqueKeysWithValues: all.map { ($0, $0.allProperties()) })
//        before.forEach {
//            let (layer, dict) = $0
//            guard let new = after[layer] else { return }
//            dict.forEach {
//                print($0.key)
//                print($0.value as? CGRect)
//                print($0.value as? CGFloat)
//                print($0.value as? CGSize)
//                let cg = $0.value as! CGColor
//                if cg.components?.isEmpty == false {
//                    print(cg.components!)
//                    print(UIColor(cgColor: cg))
//                }
//                print()
//            }
//        }
//    }
//}
//
//class MyAnimation: CAAction {
//
//    func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
//
//    }
//
//}


//public static var layoutSubviews: UIView.AnimationOptions { get }
//
//public static var allowUserInteraction: UIView.AnimationOptions { get } // turn on user interaction while animating
//
//public static var beginFromCurrentState: UIView.AnimationOptions { get } // start all views from current value, not initial value
//
//public static var `repeat`: UIView.AnimationOptions { get } // repeat animation indefinitely
//
//public static var autoreverse: UIView.AnimationOptions { get } // if repeat, run animation back and forth
//
//public static var overrideInheritedDuration: UIView.AnimationOptions { get } // ignore nested duration
//
//public static var overrideInheritedCurve: UIView.AnimationOptions { get } // ignore nested curve
//
//public static var allowAnimatedContent: UIView.AnimationOptions { get } // animate contents (applies to transitions only)
//
//public static var showHideTransitionViews: UIView.AnimationOptions { get } // flip to/from hidden position instead of adding/removing
//
//public static var overrideInheritedOptions: UIView.AnimationOptions { get } // do not inherit any options or animation type
//
//
//public static var curveEaseInOut: UIView.AnimationOptions { get } // default
//
//public static var curveEaseIn: UIView.AnimationOptions { get }
//
//public static var curveEaseOut: UIView.AnimationOptions { get }
//
//public static var curveLinear: UIView.AnimationOptions { get }
//
//
//public static var transitionFlipFromLeft: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromRight: UIView.AnimationOptions { get }
//
//public static var transitionCurlUp: UIView.AnimationOptions { get }
//
//public static var transitionCurlDown: UIView.AnimationOptions { get }
//
//public static var transitionCrossDissolve: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromTop: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromBottom: UIView.AnimationOptions { get }
//
//
//public static var preferredFramesPerSecond60: UIView.AnimationOptions { get }
//
//public static var preferredFramesPerSecond30: UIView.AnimationOptions { get }
