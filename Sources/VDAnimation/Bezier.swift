//
//  Bezier.swift
//  SuperAnimations
//
//  Created by Daniil on 23.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//
//https://cubic-bezier.com/

import UIKit
//
//  Bezier.swift
//  SuperAnimations
//
//  Created by Daniil on 23.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//
//https://cubic-bezier.com/

import UIKit

public struct BezierCurve: Equatable {
    public static let linear = BezierCurve(.zero, .one)
    public static let ease = BezierCurve(CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.25, y: 1))
    public static let easeIn = BezierCurve(CGPoint(x: 0.42, y: 0), .one)
    public static let easeOut = BezierCurve(.zero, CGPoint(x: 0.58, y: 1))
    public static let easeInOut = BezierCurve(easeIn.point1, easeOut.point2)
    
    private var start: CGPoint = .zero
    public var point1: CGPoint
    public var point2: CGPoint
    private var end: CGPoint = .one
    
    public var builtin: UIView.AnimationCurve? {
        switch self {
        case .easeIn: return .easeIn
        case .easeOut: return .easeOut
        case .easeInOut: return .easeInOut
        case .linear: return .linear
        default: return nil
        }
    }
    
    public init<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) {
        point1 = CGPoint(x: CGFloat(p1.x), y: CGFloat(p1.y))
        point2 = CGPoint(x: CGFloat(p2.x), y: CGFloat(p2.y))
        self = BezierCurve(point1, point2)
    }
    
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
    
    
    private func split(at coefficient: CGFloat) -> (BezierCurve, BezierCurve) {
        guard coefficient > 0 else {
            return (.linear, self)
        }
        guard coefficient < 1 else {
            return (self, .linear)
        }
        let p12 = CGPoint.between(.zero, point1, k: coefficient)
        let p23 = CGPoint.between(point1, point2, k: coefficient)
        let p34 = CGPoint.between(point2, .one, k: coefficient)
        let p123 = CGPoint.between(p12, p23, k: coefficient)
        let p234 = CGPoint.between(p23, p34, k: coefficient)
        let p1234 = CGPoint.between(p123, p234, k: coefficient)
        
        var curve1 = BezierCurve(p12, p123)
        curve1.end = p1234
        var curve2 = BezierCurve(p234, p34)
        curve2.start = p1234
        return (curve1, curve2)
    }
    
    public var normalized: BezierCurve {
        let length = end - start
        return BezierCurve((point1 - start) / length, (point2 - start) / length)
    }
    
    public func split(ranges: [ClosedRange<Double>]) -> [(BezierCurve, Double)] {
        return ranges.map(split)
    }
    
    public func split(range: ClosedRange<Double>) -> (BezierCurve, Double) {
        let start = CGFloat(range.lowerBound)
        let end = CGFloat(range.upperBound)
        let t1 = findT(start)
        let b1 = split(at: t1).1
        let t2 = b1.findT(end)
        let time2 = b1.value(t: t2, axe: .horizontal)
        let b2 = b1.split(at: t2).0
        let bezier = b2.normalized
        let duration = Double(time2 - value(t: t1, axe: .horizontal))
        return (bezier, duration)
    }
    
    public func y(at x: CGFloat) -> CGFloat {
        guard x > 0, x < 1 else { return x }
        var t: CGFloat = 0.0
        var x1: CGFloat = 0.0
        while t < 1, x1 < x {
            t += 0.02
            x1 = value(t: t, axe: .horizontal)
        }
        return value(t: t, axe: .vertical)
    }
    
    private func findT(_ y: CGFloat) -> CGFloat {
        guard y > 0, y < 1 else { return y }
        var t: CGFloat = 0.0
        var y1: CGFloat = 0.0
        while t < 1, y1 < y {
            t += 0.02
            y1 = value(t: t, axe: .vertical)
        }
        return max(0, t - 0.01)
    }
    
    private func value(t: CGFloat, axe: NSLayoutConstraint.Axis) -> CGFloat {
        let a = 3 * t * (1 - t) * (1 - t)
        let b = 3 * t * t * (1 - t)
        let m = (1 - t) * (1 - t) * (1 - t)
        return m * start[axe] + a * point1[axe] + b * point2[axe] + t * t * t * end[axe]
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

extension CGFloat {
    
    var export: String {
        return "\(self)".replacingOccurrences(of: "0.", with: ".")
    }
    
}

//public enum Curve {
////    case bezier(BezierCurve),  //spring
//}
//
////easeIn: y = x^1.75; x = y^(4/7)
////easeOut: y = x^1.1(2-x) = 2x - x^2; x^2 - 2x + y = 0; D = 4 - 4y; x = 2 +- √(4-4y)/2 = 2 - √(1 - y)
////easeInOut = 2x^2, x<=0.5; 1-2(x-1)^2, x > 0.5
//// sqrt(y/2)
////y = -2x^2 + 2x - 1; 2x^2 - 2x + y-1 = 0; D = 12 - 8y; x = 0.5(1 +- sqrt(3 - 2y))
//
////f(x)
////y0+f(x0+x(x1-x0))*(y1-y0)
//
////d = (x0, y0)
////k = (x1-x0, y1-y0)
////p'= p*k + d
////p = (p'- d)/k
//
//public struct BezierCurve: Equatable {
//    public static let linear = BezierCurve(.zero, .one, .linear)
//    public static let ease = BezierCurve((x: 0.25, y: 0.1), (x: 0.25, y: 1), nil)
//    public static let easeIn = BezierCurve((x: 0.45, y: 0), (1, 1), .easeIn)
//    public static let easeOut = BezierCurve((0, 0), (x: 0.55, y: 1), .easeOut) //0.58
//    public static let easeInOut = BezierCurve(easeIn.point1, easeOut.point2, .easeInOut)
//
//    private var start: CGPoint = .zero
//    public var point1: CGPoint
//    public var point2: CGPoint
//    private var end: CGPoint = .one
//    private let approximate: Approximate?
//
//    public var builtin: UIView.AnimationCurve? {
//        switch self {
//        case .easeIn:       return .easeIn
//        case .easeOut:      return .easeOut
//        case .easeInOut:    return .easeInOut
//        case .linear:       return .linear
//        default:            return nil
//        }
//    }
//
//    public static func == (lhs: BezierCurve, rhs: BezierCurve) -> Bool {
//        lhs.point1 == rhs.point1 && lhs.point1 == rhs.point1 && lhs.start == rhs.start && lhs.end == rhs.end
//    }
//
//    public init(_ p1: CGPoint, _ p2: CGPoint) {
//        self = BezierCurve(p1, p2, nil)
//    }
//
//    private init<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F), _ approximate: Approximate?) {
//        point1 = CGPoint(x: CGFloat(p1.x), y: CGFloat(p1.y))
//        point2 = CGPoint(x: CGFloat(p2.x), y: CGFloat(p2.y))
//        self.approximate = approximate
//    }
//
//    private init(_ p1: CGPoint, _ p2: CGPoint, _ approximate: Approximate?) {
//        point1 = p1
//        point2 = p2
//        self.approximate = approximate
//    }
//
//    public init<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) {
//        self = BezierCurve(p1, p2, nil)
//    }
////    x(t) = (1-t)^3 * x0 + 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3 * x3
////    y(t) = (1-t)^3 * y0 + 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3 * y3
////    x - time
////    y - progress
////    x(t) = 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3
////    y(t) = 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3
//    //3*x1*t*p^2 + 3*x2*p*t^2 + t^3
//    //
//    //    x(t) = 3t(1-t)^2 * x1 + 3t^2 * x2 - 2t^3 * x2 + t^3
//    //    y(t) = 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3
//
////         x = p123.x + (p234.x - p123.x) * k //= p123.x * (1 - k) + k * p234.x
////    p123.x = p12.x + (p23.x - p12.x) * k
////    p234.x = p23.x + (p34.x - p23.x) * k
////     p12.x = p1.x * k
////     p23.x = p1.x + (p2.x - p1.x) * k
////     p34.x = p2.x + (1 - p2.x) * k
////
////
////    p123.x = p1.x * k + (p1.x + p2.x * k - 2 * p1.x * k) * k
////    p234.x = p1.x + p2.x * k - p1.x * k + p2.x * k + k^2 - p1.x * k - 2 * p2.x * k^2 + p1.x * k^2
////
////    p234.x = p1.x + 2 * k * (p2.x - p1.x) + k^2 * (1 - 2 * p2.x + p1.x)
//
//
//    private func split(at coefficient: CGFloat) -> (BezierCurve, BezierCurve) {
//        guard coefficient > 0 else {
//            return (.linear, self)
//        }
//        guard coefficient < 1 else {
//            return (self, .linear)
//        }
//        let p12 = CGPoint.between(.zero, point1, k: coefficient)
//        let p23 = CGPoint.between(point1, point2, k: coefficient)
//        let p34 = CGPoint.between(point2, .one, k: coefficient)
//        let p123 = CGPoint.between(p12, p23, k: coefficient)
//        let p234 = CGPoint.between(p23, p34, k: coefficient)
//        let p1234 = CGPoint.between(p123, p234, k: coefficient)
//
//        var curve1 = BezierCurve(p12, p123, approximate)
//        curve1.end = p1234
//        var curve2 = BezierCurve(p234, p34, approximate)
//        curve2.start = p1234
//        return (curve1, curve2)
//    }
//
//    public var normalized: BezierCurve {
//        let length = end - start
//        let app = approximate?.normalized(start: start, end: end)
//        return BezierCurve((point1 - start) / length, (point2 - start) / length, app)
//    }
//
//    public func split(ranges: [ClosedRange<Double>]) -> [(BezierCurve, Double)] {
//        return ranges.map(split)
//    }
//
//    public func split(range: ClosedRange<Double>) -> (BezierCurve, Double) {
//        let start = CGFloat(range.lowerBound)
//        let end = CGFloat(range.upperBound)
//        let t1 = findT(start)
//        let b1 = split(at: t1).1
//        let t2 = b1.findT(end)
//        let time2 = b1.value(t: t2, axe: .horizontal)
//        let b2 = b1.split(at: t2).0
//        let bezier = b2.normalized
//        let duration = Double(time2 - value(t: t1, axe: .horizontal))
//        return (bezier, duration)
//    }
//
//    private func findT(_ y: CGFloat) -> CGFloat {
//        guard y > 0, y < 1 else { return y }
//        var t: CGFloat = 0.0
//        var y1: CGFloat = 0.0
//        while t < 1, y1 < y {
//            t += 0.02
//            y1 = value(t: t, axe: .vertical)
//        }
//        return max(0, t - 0.01)
//    }
//
//    public func y(at x: CGFloat) -> CGFloat {
//        guard x > 0, x < 1 else { return x }
//        if let app = approximate {
//            return app.y(x)
//        }
//        var t: CGFloat = 0.0
//        var x1: CGFloat = 0.0
//        while t < 1, x1 < x {
//            t += 0.02
//            x1 = value(t: t, axe: .horizontal)
//        }
//        return value(t: t, axe: .vertical)
//    }
//
//    private func value(t: CGFloat, axe: NSLayoutConstraint.Axis) -> CGFloat {
//        let a = 3 * t * (1 - t) * (1 - t)
//        let b = 3 * t * t * (1 - t)
//        let m = (1 - t) * (1 - t) * (1 - t)
//        return m * start[axe] + a * point1[axe] + b * point2[axe] + t * t * t * end[axe]
//    }
//
//    private func value(_ axe: NSLayoutConstraint.Axis, for other: CGFloat) -> CGFloat {
//        guard other != 0 else { return 0 }
//        guard other != 1 else { return 1 }
//        let axe0 = axe.inverted
//        let a = 1 - 3 * point2[axe0] + 3 * point1[axe0]
//        let b = 3 * point2[axe0] - 6 * point1[axe0]
//        let c = 3 * point2[axe0]
//        let d = -other
//        let _y: (CGFloat) -> CGFloat = { $0 - b / (3 * a) }
//        let b2 = b * b
//        let b3 = b2 * b
//        let a2 = a * a
//        let a3 = a2 * a
//        let p = -b2 / (3 * a2) + c / a
//        let q = 2 * b3 / (27 * a3) - b * c / (3 * a2) + d / a
//        let q1 = (p * p * p / 27) + (q * q / 4)
//        let w = pow(-q / 2 + sqrt(q1), 1 / 3)
//        let z = pow(-q / 2 - sqrt(q1), 1 / 3)
//        let y1 = w + z
//        let x1 = _y(y1)
//        if q1 > 0 {
//            return x1
//        }
//        return 0
//    }
//
//    public static func between(_ c1: BezierCurve, _ c2: BezierCurve, k: CGFloat = 0.5) -> BezierCurve {
//        return BezierCurve(CGPoint.between(c1.point1, c2.point1, k: k), CGPoint.between(c1.point2, c2.point2, k: k))
//    }
//
//}
//
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
//
//extension NSLayoutConstraint.Axis {
//
//    public var inverted: NSLayoutConstraint.Axis {
//        switch self {
//        case .horizontal:   return .vertical
//        default:            return .horizontal
//        }
//    }
//
//}
//
//fileprivate struct Approximate {
//    private let yByX: (CGFloat) -> CGFloat
//    private let xByY: (CGFloat) -> CGFloat
//    var start: CGPoint
//    var end: CGPoint
//
//    static let linear = Approximate(yx: { $0 }, xy: { $0 })
//    static let easeIn = Approximate(yx: { pow($0, 1.75) }, xy: { pow($0, 4/7) })
//    static let easeOut = Approximate(yx: { $0 * (2 - $0) }, xy: { 2 - sqrt(1 - $0) }) //0.58
//    static let easeInOut = Approximate(
//        yx: {
//            let sqr = ($0 - 1)
//            return $0 < 0.5 ? 2 * $0 * $0 : 1 - 2 * sqr * sqr
//        },
//        xy: {
//            if $0 < 0.5 {
//                return sqrt($0 / 2)
//            } else {
//                return 1 - sqrt((1 - $0) / 2)
//            }
//        }
//    )
//
//    init(_ p1: CGPoint = .zero, _ p2: CGPoint = .one, yx: @escaping (CGFloat) -> CGFloat, xy: @escaping (CGFloat) -> CGFloat) {
//        start = p1
//        end = p2
//        yByX = yx
//        xByY = xy
//    }
//
//    func normalized(start p0: CGPoint, end p1: CGPoint) -> Approximate {
//        let lenght = end - start
//        let newStart = lenght * p0
//        let newEnd = lenght * p1
//        return Approximate(newStart, newEnd, yx: yByX, xy: xByY)
//    }
//
//    func x(_ y: CGFloat) -> CGFloat {
//        let lenght = end - start
//        return (xByY(y * lenght.y + start.y) - start.x) / lenght.x
//    }
//
//    func y(_ x: CGFloat) -> CGFloat {
//        let lenght = end - start
//        return (yByX(x * lenght.x + start.x) - start.y) / lenght.y
//    }
//
//}
