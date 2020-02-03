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
        
    public init(getter: @escaping () -> T?, setter: @escaping (T?) -> (), scale: @escaping (T, Double, T) -> T, value: T, animatorType: A.Type) {
        self.scale = scale
        self.setter = setter
        self.initial = getter() ?? value
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
    
    public init(getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            getter: getter, setter: setter,
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
    
    public init(getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            getter: getter, setter: setter,
            scale: {
                var lenght = $2 - $0
                lenght.scale(by: $1)
                return $0 + lenght
            },
            value: value, animatorType: animatorType
        )
    }
    
}

extension PropertyAnimator where T: Scalable {
    
    public init(getter: @escaping () -> T?, setter: @escaping (T?) -> (), value: T, animatorType: A.Type) {
        self = PropertyAnimator(
            getter: getter, setter: setter,
            scale: { $0 + ($2 - $0).scaled(by: $1) },
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
    
    public static func += (lhs: inout CGRect, rhs: CGRect) {
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
    var scaleData: ScaledData { get set }
}

extension ScalableConvertable where Self: Scalable, ScaledData == Self {
    public var scaleData: Self { get { self } set { self = newValue } }
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
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if getRed(&r, green: &g, blue: &b, alpha: &a) {
                return ScaledData(red: r, green: g, blue: b, alpha: a)
            }
            return .zero
        }
        set {
            self.red
            self = UIColor(red: newValue.red, green: newValue.red, blue: newValue.red, alpha: newValue.red)
        }
    }
    
}
