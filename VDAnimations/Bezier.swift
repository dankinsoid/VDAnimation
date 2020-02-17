//
//  Bezier.swift
//  SuperAnimations
//
//  Created by Daniil on 23.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//
//https://cubic-bezier.com/

import UIKit

public enum Curve {
//    case bezier(BezierCurve),  //spring
}

//easeIn = x^1.75;
//easeOut = x^1.1(2-x)
//easeInOut = 2x^2, x<=0.5; -1+(2-2x)x, x > 0.5

//f(x)
//y0+f(x0+x(x1-x0))*(y1-y0)

//d = (x0, y0)
//k = (x1-x0, y1-y0)
//p'= p*k + d
//p = (p'- d)/k

public struct BezierCurve: Equatable {
    public static let linear = BezierCurve(.zero, .one, { $0 })
    public static let ease = BezierCurve((x: 0.25, y: 0.1), (x: 0.25, y: 1), nil)
    public static let easeIn = BezierCurve((x: 0.45, y: 0), (1, 1), { pow($0, 1.75) })
    public static let easeOut = BezierCurve((0, 0), (x: 0.55, y: 1), { pow($0, 1.1) * (2 - $0) }) //0.58
    public static let easeInOut = BezierCurve(easeIn.point1, easeOut.point2, {
        let sqr = $0 * $0
        return $0 < 0.5 ? 2 * sqr : ($0 * (2 - 2 * $0) - 1)
    })
    
    private var start: CGPoint = .zero
    public var point1: CGPoint
    public var point2: CGPoint
    private var end: CGPoint = .one
    private var approximate: ((CGFloat) -> CGFloat)?
    
    public var reversed: BezierCurve {
        BezierCurve((1 - point2.x, 1 - point2.y), (1 - point1.x, 1 - point1.y))
    }
    
    public var builtin: UIView.AnimationCurve? {
        switch self {
        case .easeIn:       return .easeIn
        case .easeOut:      return .easeOut
        case .easeInOut:    return .easeInOut
        case .linear:       return .linear
        default:            return nil
        }
    }
    
    public static func == (lhs: BezierCurve, rhs: BezierCurve) -> Bool {
        lhs.point1 == rhs.point1 && lhs.point1 == rhs.point1 && lhs.start == rhs.start && lhs.end == rhs.end
    }
    
    public init(_ p1: CGPoint, _ p2: CGPoint) {
        self = BezierCurve(p1, p2, nil)
    }
    
    private init<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F), _ fun: ((CGFloat) -> CGFloat)?) {
        point1 = CGPoint(x: CGFloat(p1.x), y: CGFloat(p1.y))
        point2 = CGPoint(x: CGFloat(p2.x), y: CGFloat(p2.y))
        approximate = fun
    }
    
    private init(_ p1: CGPoint, _ p2: CGPoint, _ fun: ((CGFloat) -> CGFloat)?) {
        point1 = p1
        point2 = p2
        approximate = fun
    }
    
    public init<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) {
        self = BezierCurve(p1, p2, nil)
    }
//    x(t) = (1-t)^3 * x0 + 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3 * x3
//    y(t) = (1-t)^3 * y0 + 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3 * y3
//    x - time
//    y - progress
//    x(t) = 3t(1-t)^2 * x1 + 3t^2 * (1-t) * x2 + t^3
//    y(t) = 3t(1-t)^2 * y1 + 3t^2 * (1-t) * y2 + t^3
    
    //    x(t) = 3t(1-t)^2 * x1 + 3t^2 * x2 - 2t^3 * x2 + t^3
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
    
    private func findT(_ y: CGFloat) -> CGFloat {
        guard y > 0, y < 1 else { return y }
        if let fun = approximate {
            
        }
        var t: CGFloat = 0.0
        var y1: CGFloat = 0.0
        while t < 1, y1 < y {
            t += 0.02
            y1 = value(t: t, axe: .vertical)
        }
        return max(0, t - 0.01)
    }
    
    func progress(at time: CGFloat) -> CGFloat {
        guard time > 0, time < 1 else { return time }
        var t: CGFloat = 0.0
        var x1: CGFloat = 0.0
        while t < 1, x1 < time {
            t += 0.02
            x1 = value(t: t, axe: .horizontal)
        }
        return value(t: t, axe: .vertical)
    }
    
    private func value(t: CGFloat, axe: NSLayoutConstraint.Axis) -> CGFloat {
        let a = 3 * t * (1 - t) * (1 - t)
        let b = 3 * t * t * (1 - t)
        let m = (1 - t) * (1 - t) * (1 - t)
        return m * start[axe] + a * point1[axe] + b * point2[axe] + t * t * t * end[axe]
    }
    
    private func value(_ axe: NSLayoutConstraint.Axis, for other: CGFloat) -> CGFloat {
        guard other != 0 else { return 0 }
        guard other != 1 else { return 1 }
        let axe0 = axe.inverted
        let a = 1 - 3 * point2[axe0] + 3 * point1[axe0]
        let b = 3 * point2[axe0] - 6 * point1[axe0]
        let c = 3 * point2[axe0]
        let d = -other
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

extension CGPoint: AdditiveArithmetic {
    
    public static let one = CGPoint(x: 1, y: 1)
    
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

extension NSLayoutConstraint.Axis {
    
    public var inverted: NSLayoutConstraint.Axis {
        switch self {
        case .horizontal:   return .vertical
        default:            return .horizontal
        }
    }
    
}

indirect enum Operation<T: FloatingPoint> {
    case value(T), multiply(Operation<T>, Operation<T>), plus(Operation<T>, Operation<T>)
    
    func compute() -> T {
        switch self {
        case .value(let result):
            return result
        case .multiply(let lhs, let rhs):
            return lhs.compute() * rhs.compute()
        case .plus(let lhs, let rhs):
            return lhs.compute() + rhs.compute()
        }
    }
}

indirect enum Func<T: BinaryFloatingPoint>: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    typealias FloatLiteralType = Double
    typealias IntegerLiteralType = Int
    
    case x, const(T), multiply(Func), plus(Func), pow(Func), f(Func, Func), ln(Func)
    
    init(floatLiteral value: Double) {
        self = .const(T.init(value))
    }
    
    init(integerLiteral value: Int) {
        self = .const(T.init(value))
    }
    
    subscript(_ value: T) -> T {
        switch self {
        case .x:
            return value
        case .const(let result):
            return result
        case .multiply(let rhs):
            return value * rhs[value]
        case .plus(let rhs):
            return value + rhs[value]
        case .f(let f, let g):
            return f.simplify(value)[g[value]]
        case .pow(let rhs):
            let power = Double(rhs[value])
            if power == -1 { return 1 / value }
            return T.init(Darwin.pow(Double(value), power))
        case .ln(let rhs):
            return T.init(Darwin.log(Double(rhs[value])))
        }
    }
    
    func simplify(_ value: T) -> Func {
        switch self {
        case .x, .const:
            return self
        case .multiply(let rhs):
            return .multiply(.const(rhs[value]))
        case .plus(let rhs):
            return .plus(.const(rhs[value]))
        case .f(let f, let g):
            return .f(f.simplify(value), .const(g[value]))
        case .pow(let rhs):
            return .pow(.const(rhs[value]))
        case .ln(let rhs):
            return .ln(.const(rhs[value]))
        }
    }
    
    func simplify() -> Func {
        switch self {
        case .x, .const:
            return self
        case .multiply(let rhs):
            let simp = rhs.simplify()
            if let k = simp.count(), k == 1 {
                return .x
            }
            return .multiply(simp)
        case .plus(let rhs):
            let simp = rhs.simplify()
            if let k = simp.count(), k == 0 {
                return .x
            }
            return .plus(simp)
        case .f(let f, let g):
            ///2 + 3 + 5 = .f(.plus(.f(.plus(3), 2)), 5)
            let simp = g.simplify()
            if let k = simp.count() {
                return f.simplify(k)
            }
            return .f(f.simplify(), simp)
        case .pow(let rhs):
            let simp = rhs.simplify()
            if let k = simp.count() {
                if k == 0 {
                    return 1
                } else if k == 1 {
                    return .x
                }
            }
            return .pow(simp)
        case .ln(let rhs):
            if let k = rhs.simplify().count(), Double(k) == M_E {
                return 1
            }
            return .ln(rhs.simplify())
        }
    }
    
    func count() -> T? {
        switch self {
        case .const(let result):
            return result
        case .ln(let rhs):
            if let value = rhs.count() {
                return Func.ln(.const(value))[value]
            }
        case .f(let f, let g):
            if let value = g.count() {
                return Func.f(f, .const(value))[value]
            }
        default:
            break
        }
        return nil
    }
    
    var derivative: Func {
        switch self {
        case .x:
            return 1
        case .const:
            return 0
        case .multiply(let rhs):
            return rhs + .x * rhs.derivative
        case .plus(let rhs):
            return 1 + rhs.derivative
        case .f(let f, let g):
            switch f {
            case .x, .const, .ln:
                return f.of(g).derivative
            case .multiply(let rhs):
                return (rhs.derivative * g) + (rhs * g.derivative)
                    //.f(.plus(.f(.multiply(rhs.derivative), g)), .f(.multiply(g.derivative), rhs))
            case .plus(let rhs):
                return rhs.derivative + g.derivative
//                return .f(.plus(rhs.derivative), g.derivative)
            case .f:
                return .f(of(f).derivative * f.derivative, g)
            case .pow(let rhs):
                return self * (.ln(g) * rhs).derivative
            }
        case .pow(let rhs):
            ///x ^ g(x) = e ^ (ln(x) * g(x)) = e^(f(x)); f'(x) * e^f(x) = (ln(x) * g(x))' * e^(ln(x) * g(x))
            return (.ln(.x) * rhs).derivative * self
        case .ln(let rhs):
            return rhs.derivative / rhs
        }
    }
    
    func of(_ x: Func) -> Func {
        switch self {
        case .x:                    return x
        case .const:                return self
        case .multiply(let rhs):    return .multiply(rhs.of(x))
        case .plus(let rhs):        return .plus(rhs.of(x))
        case .f(let f, let g):      return .f(f.of(x), g.of(x))
        case .pow(let rhs):         return .pow(rhs.of(x))
        case .ln(let rhs):          return .ln(rhs.of(x))
        }
    }
    
//    subscript(_ value: Func<T>) -> Func<T> {
//        .f(self, value)
//    }
    
    /// f(x) = x * k, f(x) = x / k
    /// y = x / (x + 2), y * (x + 2) = x, y * x + y * 2 = x , 2 * y / (1 - y);
    /// f(x) = x, x = f(x)
    /// f(x) = 2, x = any
    /// f(x) = x + 2, x = f(x) - 2
    /// x + 2 + 4, (x + 2) + 3, .f(.plus(.const(3)), .plus(.const(2)))
    /// f(x) = x ^ 2, x = f(x) ^ 0.5
    
//    var reverse: Func<T> {
//        switch self {
//        case .x:
//            return .x
//        case .const:
//            return .multiply(1)
//        case .multiply(let rhs):
//            return .x / rhs
//        case .plus(let rhs):
//            return 0 - rhs
//        case .pow(let power):
//            return .pow(<#T##Func<BinaryFloatingPoint>#>)
//        case .f(_, _):
//            <#code#>
//        }
//    }
    
    public static func +(_ lhs: Func<T>, _ rhs: Func<T>) -> Func<T> { .f(.plus(rhs), lhs) }
    public static func *(_ lhs: Func<T>, _ rhs: Func<T>) -> Func<T> { .f(.multiply(rhs), lhs) }
    public static func /(_ lhs: Func<T>, _ rhs: Func<T>) -> Func<T> { lhs * (rhs ^ -1) }
    public static func ^(_ lhs: Func<T>, _ rhs: Func<T>) -> Func<T> { .f(.pow(rhs), lhs) }
    public static func -(_ lhs: Func<T>, _ rhs: Func<T>) -> Func<T> { lhs + (-1 * rhs) }
}

prefix func -<T: BinaryFloatingPoint>( _ rhs: Func<T>) -> Func<T> { -1 * rhs }
prefix func +<T: BinaryFloatingPoint>( _ rhs: Func<T>) -> Func<T> { rhs }

extension Func: CustomStringConvertible {
    var description: String {
        switch self {
        case .x:
            return "x"
        case .const(let result):
            return "\(result)"
        case .multiply(let rhs):
            return " * " + rhs.description
        case .plus(let rhs):
            return " + " + rhs.description
        case .f(let f, let g):
            return "(\(g.description)\(f.description))"
        case .pow(let rhs):
            return "^" + rhs.description
        case .ln(let rhs):
            return "ln(\(rhs))"
        }
    }
    
    var sign: String {
        switch self {
        case .x:
            return "1"
        case .const(let result):
            return "C"
        case .multiply(let rhs):
            return "*"
        case .plus(let rhs):
            return "+"
        case .f(let f, let g):
            return "f(x)"
        case .pow(let rhs):
            return "^"
        case .ln:
            return "ln"
        }
    }
}
