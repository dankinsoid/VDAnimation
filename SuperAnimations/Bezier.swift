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
    
         x = p123.x + (p234.x - p123.x) * k //= p123.x * (1 - k) + k * p234.x
    p123.x = p12.x + (p23.x - p12.x) * k
    p234.x = p23.x + (p34.x - p23.x) * k
     p12.x = p1.x * k
     p23.x = p1.x + (p2.x - p1.x) * k
     p34.x = p2.x + (1 - p2.x) * k
    
    
    p123.x = p1.x * k + (p1.x + p2.x * k - 2 * p1.x * k) * k
    p234.x = p1.x + p2.x * k - p1.x * k + p2.x * k + k^2 - p1.x * k - 2 * p2.x * k^2 + p1.x * k^2
    
    p234.x = p1.x + 2 * k * (p2.x - p1.x) + k^2 * (1 - 2 * p2.x + p1.x)
    
    
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
