//
//  Bezier.swift
//  SuperAnimations
//
//  Created by Daniil on 23.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public struct BezierCurve {
    public static let linear = BezierCurve(.zero, .one)
    public static let ease = BezierCurve(CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.25, y: 1))
    public static let easeIn = BezierCurve(CGPoint(x: 0.42, y: 0), .one)
    public static let easeOut = BezierCurve(.zero, CGPoint(x: 0.58, y: 1))
    public static let easeInOut = BezierCurve(easeIn.point1, easeOut.point2)
    
    public var point1: CGPoint
    public var point2: CGPoint
    
    public init(_ p1: CGPoint, _ p2: CGPoint) {
        point1 = p1
        point2 = p2
    }
//    x(t) = (1-t)^3 * x0 + 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3 * x3
//    y(t) = (1-t)^3 * y0 + 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3 * y3
//    x - time
//    y - progress
//    x(t) = 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3
//    y(t) = 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3
    
//         x = p123.x + (p234.x - p123.x) * k //= p123.x * (1 - k) + k * p234.x
//    p123.x = p12.x + (p23.x - p12.x) * k
//    p234.x = p23.x + (p34.x - p23.x) * k
//     p12.x = p1.x * k
//     p23.x = p1.x + (p2.x - p1.x) * k
//     p34.x = p2.x + (1 - p2.x) * k
//
//
//    p123.x = p1.x * k + (p1.x + p2.x * k - 2 * p1.x * k) * k
//    p234.x = p1.x + p2.x * k - p1.x * k + p2.x * k + k^2 - p1.x * k - 2 * p2.x * k^2 + p1.x * k^2
//
//    p234.x = p1.x + 2 * k * (p2.x - p1.x) + k^2 * (1 - 2 * p2.x + p1.x)
    
    
    public func split(at coefficient: CGFloat) -> (BezierCurve, BezierCurve) {
        guard coefficient > 0 else {
            return (.linear, self)
        }
        let p12 = CGPoint.between(.zero, point1, k: coefficient)
        let p23 = CGPoint.between(point1, point2, k: coefficient)
        let p34 = CGPoint.between(point2, .one, k: coefficient)
        let p123 = CGPoint.between(p12, p23, k: coefficient)
        let p234 = CGPoint.between(p23, p34, k: coefficient)
        let p1234 = CGPoint.between(p123, p234, k: coefficient)
        
        let k2 = .one - p1234
        let curve1 = BezierCurve(p12 / p1234, p123 / p1234)
        let curve2 = BezierCurve((p234 - p1234) / k2, (p34 - p1234) / k2)
        return (curve1, curve2)
    }
    
    private func findX(_ y: CGFloat) -> CGFloat {
        guard y != 0 else { return 0 }
        guard y != 1 else { return 1 }
        let a = 1 - 3 * point2.y + 3 * point1.y
        let b = 3 * point2.y - 6 * point1.y
        let c = 3 * point2.y
        let d = -y
        let _y: (CGFloat) -> CGFloat = { $0 - b / (3 * a) }
        let b2 = b * b
        let b3 = b2 * b
        let a2 = a * a
        let a3 = a2 * a
        let p = -b2 / (3 * a2) + c / a
        let q = 2 * b3 / (27 * a3) - b * c / (3 * a2) + d / a
        let q1 = (p * p * p / 27) + (q * q / 4)
        let w = pow(-q / 2 + sqrt(q1), 1 / 3)
        let z = pow(-q / 2 - sqrt(q1), 1 / 3)
        let y1 = w + z
        let x1 = _y(y1)
        if q1 > 0 {
            return x1
        }
        return 0
    }
    
    
    public static func between(_ c1: BezierCurve, _ c2: BezierCurve, k: CGFloat = 0.5) -> BezierCurve {
        return BezierCurve(CGPoint.between(c1.point1, c2.point1, k: k), CGPoint.between(c1.point2, c2.point2, k: k))
    }
    
}

extension CGPoint {
    
    static let one = CGPoint(x: 1, y: 1)
    
    static func between(_ p1: CGPoint, _ p2: CGPoint, k: CGFloat) -> CGPoint {
        return CGPoint(x: p1.x + (p2.x - p1.x) * k, y: p1.y + (p2.y - p1.y) * k)
    }
    
    static func /(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
    
    static func *(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    static func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    
}
