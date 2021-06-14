//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit

extension CGPoint: AdditiveArithmetic {
	
	static let one = CGPoint(x: 1, y: 1)
	
	public static func between(_ p1: CGPoint, _ p2: CGPoint, k: CGFloat) -> CGPoint {
		return CGPoint(x: p1.x + (p2.x - p1.x) * k, y: p1.y + (p2.y - p1.y) * k)
	}
	
	public static func /(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
	}
	
	public static func *(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
	}
	
	public static func *(_ lhs: CGPoint, _ rhs: CGSize) -> CGPoint {
		return CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
	}
	
	public static func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}
	
	public static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}
	
	public static func +=(lhs: inout CGPoint, rhs: CGPoint) {
		lhs = lhs + rhs
	}
	
	public static func -=(lhs: inout CGPoint, rhs: CGPoint) {
		lhs = lhs - rhs
	}
	
	public subscript(_ axe: NSLayoutConstraint.Axis) -> CGFloat {
		switch axe {
		case .horizontal:   return x
		default:            return y
		}
	}
}
