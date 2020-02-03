//
//  PropertyAnimator.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import SwiftUI

public protocol Scalable: AdditiveArithmetic, ScalableConvertable {
    func scaled(by rhs: Double) -> Self
}

extension Scalable {
    public typealias ScaleData = Self
}

public struct PropertyAnimator<T, A: AnimationClosureProviderProtocol>: AnimationProviderProtocol {
    private let initial: T
    private let value: T
    private let scale: (T, Double, T) -> T
    private let setter: (T?) -> ()
        
    init(from initial: T, getter: @escaping () -> T?, setter: @escaping (T?) -> (), scale: @escaping (T, Double, T) -> T, value: T, animatorType: A.Type) {
        self.scale = scale
        self.setter = setter
        self.initial = initial
        self.value = value
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        A.init({ self.setter(self.value) }).start(with: options, completion)
    }
    
    public func canSet(state: AnimationState) -> Bool { true }
    
    public func set(state: AnimationState) {
        switch state {
        case .start:
            setter(initial)
        case .progress(let k):
            setter(scale(initial, k, value))
        case .end:
            setter(value)
        }
    }
    
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension PropertyAnimator where T: Animatable {
    
    init(from initial: T, getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            from: initial, getter: getter, setter: setter,
            scale: {
                var result = $0
                var lenght = $2.animatableData - $0.animatableData
                lenght.scale(by: $1)
                result.animatableData += lenght
                return result
            },
            value: value, animatorType: animatorType
        )
    }
    
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension PropertyAnimator where T: VectorArithmetic {
    
    init(from initial: T, getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            from: initial, getter: getter, setter: setter,
            scale: {
                var lenght = $2 - $0
                lenght.scale(by: $1)
                return $0 + lenght
            },
            value: value, animatorType: animatorType
        )
    }
    
}

extension PropertyAnimator where T: ScalableConvertable {
    
    init(from initial: T, getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            from: initial, getter: getter, setter: setter,
            scale: { T.init(scaleData: $0.scaleData + ($2.scaleData - $0.scaleData).scaled(by: $1)) },
            value: value, animatorType: animatorType
        )
    }
    
}

extension CGFloat: Scalable {
    public func scaled(by rhs: Double) -> CGFloat { self * CGFloat(rhs) }
}
extension Float: Scalable {
    public func scaled(by rhs: Double) -> Float { self * Float(rhs) }
}
extension Double: Scalable {
    public func scaled(by rhs: Double) -> Double { self * rhs }
}

extension CGPoint: Scalable {
    public func scaled(by rhs: Double) -> CGPoint { CGPoint(x: x.scaled(by: rhs), y: y.scaled(by: rhs)) }
}

extension CGSize: Scalable {
    
    public static func -=(lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs - rhs
    }
    
    public static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    public static func += (lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs + rhs
    }
    
    public static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public func scaled(by rhs: Double) -> CGSize {
        CGSize(width: width.scaled(by: rhs), height: height.scaled(by: rhs))
    }
    
}

extension CGRect: Scalable {
    
    public static func -=(lhs: inout CGRect, rhs: CGRect) {
        lhs = lhs - rhs
    }
    
    public static func -(lhs: CGRect, rhs: CGRect) -> CGRect {
        CGRect(origin: lhs.origin - rhs.origin, size: lhs.size - rhs.size)
    }
    
    public static func +=(lhs: inout CGRect, rhs: CGRect) {
        lhs = lhs + rhs
    }
    
    public static func +(lhs: CGRect, rhs: CGRect) -> CGRect {
        CGRect(origin: lhs.origin + rhs.origin, size: lhs.size + rhs.size)
    }
    
    public func scaled(by rhs: Double) -> CGRect {
        CGRect(origin: origin.scaled(by: rhs), size: size.scaled(by: rhs))
    }
    
}

public protocol ScalableConvertable {
    associatedtype ScaledData: Scalable
    var scaleData: ScaledData { get }
    init(scaleData: ScaledData)
}

extension ScalableConvertable where Self: Scalable, ScaledData == Self {
    public var scaleData: Self { self }
    public init(scaleData: Self) { self = scaleData }
}

extension ScalableConvertable where Self == UIColor {
    
    public init(scaleData: UIColor.ScaledData) {
        self = UIColor(red: scaleData.red, green: scaleData.green, blue: scaleData.blue, alpha: scaleData.alpha)
    }
    
}

extension UIColor: ScalableConvertable {
    
    public struct ScaledData: Scalable {
        
        public static var zero: ScaledData { ScaledData(red: 0, green: 0, blue: 0, alpha: 0) }
        
        public let red: CGFloat
        public let green: CGFloat
        public let blue: CGFloat
        public let alpha: CGFloat
        
        public init(red r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) {
            red = r.truncatingRemainder(dividingBy: 1)
            green = g.truncatingRemainder(dividingBy: 1)
            blue = b.truncatingRemainder(dividingBy: 1)
            alpha = a.truncatingRemainder(dividingBy: 1)
        }
        
        public func scaled(by rhs: Double) -> ScaledData {
            let rhs = CGFloat(rhs)
            return ScaledData(red: red * rhs, green: green * rhs, blue: blue * rhs, alpha: alpha * rhs)
        }
        
        public static func +(lhs: ScaleData, rhs: ScaleData) -> ScaleData {
            ScaledData(red: lhs.red + rhs.red, green: lhs.green + rhs.green, blue: lhs.blue + rhs.blue, alpha: lhs.alpha + rhs.alpha)
        }
        
        public static func +=(lhs: inout ScaledData, rhs: ScaledData) {
            lhs = lhs + rhs
        }

        public static func -(lhs: ScaledData, rhs: ScaledData) -> ScaledData {
            ScaledData(red: lhs.red - rhs.red, green: lhs.green - rhs.green, blue: lhs.blue - rhs.blue, alpha: lhs.alpha - rhs.alpha)
        }
        
        public static func -=(lhs: inout ScaledData, rhs: ScaledData) {
            lhs = lhs - rhs
        }
        
    }
    
    public var scaleData: ScaledData {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return ScaledData(red: r, green: g, blue: b, alpha: a)
        }
        return .zero
    }
    
}

extension CGAffineTransform: Scalable {
    
    public static var zero: CGAffineTransform { .identity }
    
    public func scaled(by rhs: Double) -> CGAffineTransform {
        concatenating(CGAffineTransform(a: CGFloat(rhs), b: 0, c: 0, d: CGFloat(rhs), tx: 0, ty: 0))
    }
    
    public static func +(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        lhs.concatenating(rhs)
    }
    
    public static func +=(lhs: inout CGAffineTransform, rhs: CGAffineTransform) {
        lhs = lhs + rhs
    }
    
    public static func -(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        lhs.concatenating(rhs.inverted())
    }
    
    public static func -=(lhs: inout CGAffineTransform, rhs: CGAffineTransform) {
        lhs = lhs - rhs
    }
    
}

extension CATransform3D: Scalable {
    public static var zero: CATransform3D { CATransform3DIdentity }
    public struct Row: Equatable {
        public let (x1, x2, x3, x4): (CGFloat, CGFloat, CGFloat, CGFloat)
    }
    public struct Matrix: Equatable {
        public let (x1, x2, x3, x4): (Row, Row, Row, Row)
        public init(_ x1: (CGFloat, CGFloat, CGFloat, CGFloat), _ x2: (CGFloat, CGFloat, CGFloat, CGFloat), _ x3: (CGFloat, CGFloat, CGFloat, CGFloat), _ x4: (CGFloat, CGFloat, CGFloat, CGFloat)) {
            self.x1 = Row(x1: x1.0, x2: x1.1, x3: x1.2, x4: x1.3)
            self.x2 = Row(x1: x2.0, x2: x2.1, x3: x2.2, x4: x2.3)
            self.x3 = Row(x1: x3.0, x2: x3.1, x3: x3.2, x4: x3.3)
            self.x4 = Row(x1: x4.0, x2: x4.1, x3: x4.2, x4: x4.3)
        }
    }
    
    public var matrix: Matrix { Matrix(
        (m11, m12, m13, m14),
        (m21, m22, m23, m24),
        (m31, m32, m33, m34),
        (m41, m42, m43, m44)
        )
    }
    
    public init(_ m: Matrix) {
        self = CATransform3D(
            m11: m.x1.x1, m12: m.x1.x2, m13: m.x1.x3, m14: m.x1.x4,
            m21: m.x2.x1, m22: m.x2.x2, m23: m.x2.x3, m24: m.x2.x4,
            m31: m.x3.x1, m32: m.x3.x2, m33: m.x3.x3, m34: m.x3.x4,
            m41: m.x4.x1, m42: m.x4.x2, m43: m.x4.x3, m44: m.x4.x4
        )
    }
    
    public func scaled(by rhs: Double) -> CATransform3D {
        let k = CGFloat(rhs)
        return CATransform3D(
            m11: k * m11, m12: k * m12, m13: k * m13, m14: k * m14,
            m21: k * m21, m22: k * m22, m23: k * m23, m24: k * m24,
            m31: k * m31, m32: k * m32, m33: k * m33, m34: k * m34,
            m41: k * m41, m42: k * m42, m43: k * m43, m44: k * m44
        )
    }
    
    public static func ==(lhs: CATransform3D, rhs: CATransform3D) -> Bool {
        lhs.matrix == rhs.matrix
    }
    
    public static func +(lhs: CATransform3D, rhs: CATransform3D) -> CATransform3D {
        operation(lhs: lhs, rhs: rhs, o: +)
    }
    
    public static func +=(lhs: inout CATransform3D, rhs: CATransform3D) {
        lhs = lhs + rhs
    }
    
    public static func -(lhs: CATransform3D, rhs: CATransform3D) -> CATransform3D {
        operation(lhs: lhs, rhs: rhs, o: -)
    }
    
    public static func -=(lhs: inout CATransform3D, rhs: CATransform3D) {
        lhs = lhs - rhs
    }
    
    private static func operation(lhs: CATransform3D, rhs: CATransform3D, o: @escaping (CGFloat, CGFloat) -> CGFloat) -> CATransform3D {
        let op: (KeyPath<CATransform3D, CGFloat>) -> CGFloat = {
            o(lhs[keyPath: $0], rhs[keyPath: $0])
        }
        return CATransform3D(
            m11: op(\.m11), m12: op(\.m12), m13: op(\.m13), m14: op(\.m14),
            m21: op(\.m21), m22: op(\.m22), m23: op(\.m23), m24: op(\.m24),
            m31: op(\.m31), m32: op(\.m32), m33: op(\.m33), m34: op(\.m34),
            m41: op(\.m41), m42: op(\.m42), m43: op(\.m43), m44: op(\.m44)
        )
    }
    
}

extension Optional: ScalableConvertable where Wrapped: ScalableConvertable {
    public typealias ScaledData = Wrapped.ScaledData
    public var scaleData: Wrapped.ScaledData { self?.scaleData ?? .zero }
    
    public init(scaleData: Wrapped.ScaledData) {
        self = .some(Wrapped.init(scaleData: scaleData))
    }
    
}
