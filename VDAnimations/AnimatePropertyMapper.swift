//
//  Bases.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit
import SwiftUI

@dynamicMemberLookup
public struct AnimatePropertyMapper<R, T> {
    fileprivate let object: R
    private let keyPath: ReferenceWritableKeyPath<R, T>
    
    fileprivate init(object: R, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.keyPath = keyPath
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D>(object: object, keyPath: kp)
    }
    
}

private struct AnimatedPropertySetter<R, T, A: AnimationClosureProviderProtocol> {
    fileprivate let object: R
    private let scale: (T, Double, T) -> T
    private let getter: () -> T?
    private let setter: (T?) -> ()
    
    fileprivate init(object: R, getter: @escaping () -> T?, setter: @escaping (T?) -> (), scale: @escaping (T, Double, T) -> T) {
        self.getter = getter
        self.setter = setter
        self.object = object
        self.scale = scale
    }
    
    func set(_ value: T) -> AnimationProviderProtocol {
        return _set(from: nil, value)
    }
    
    func set(from initial: T, _ value: T) -> AnimationProviderProtocol {
        return _set(from: initial, value)
    }
    
     func _set(from initial: T?, _ value: T) -> AnimationProviderProtocol {
        return PropertyAnimator(
            from: initial,
            getter: getter,
            setter: setter,
            scale: scale,
            value: value,
            animatorType: A.self
        )
    }
    
    func set(_ a: T, _ b: T, _ values: [T]) -> AnimationProviderProtocol {
        set([a, b] + values)
    }
    
    func set(_ values: [T]) -> AnimationProviderProtocol {
        guard values.count > 1 else {
            return Sequential(values.map { set($0) })
        }
        var array = values
        var animations = [set(values[0])]
        array.removeFirst()
        animations += sequential(from: values[0], array)
        return Sequential(animations)
    }
    
    func set(from initial: T, _ a: T, _ b: T, _ values: [T]) -> AnimationProviderProtocol {
        set(from: initial, [a, b] + values)
    }
    
    func set(from initial: T, _ values: [T]) -> AnimationProviderProtocol {
        Sequential(sequential(from: initial, values))
    }
    
    private func sequential(from initial: T, _ values: [T]) -> [AnimationProviderProtocol] {
        guard values.count > 0 else {
            return [set(from: initial, initial)]
        }
        var array = values
        var from = initial
        var animations: [AnimationProviderProtocol] = []
        while !array.isEmpty {
            let second = array.removeFirst()
            animations.append(set(from: from, second))
            from = second
        }
        return animations
    }
    
}

extension AnimatedPropertySetter where T: Comparable {
    
    fileprivate func set(_ range: Gradient<T>) -> AnimationProviderProtocol {
        set(from: range.from, range.to)
    }
    
}

@dynamicMemberLookup
public struct AnimatedPropertyMaker<R> {
    private var object: R
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatePropertyMapper<R, D> {
        AnimatePropertyMapper(object: object, keyPath: keyPath)
    }
    
}

extension AnimatePropertyMapper where R: UIKitPropertySettable, T: ScalableConvertable {
    
    private var setter: AnimatedPropertySetter<R, T, Animate> {
        AnimatedPropertySetter(
            object: object,
            getter: {[weak object, keyPath] in object?[keyPath: keyPath] },
            setter: {[weak object, keyPath] in if let v = $0 { object?[keyPath: keyPath] = v } },
            scale: { T.init(scaleData: $0.scaleData + ($2.scaleData - $0.scaleData).scaled(by: $1)) }
        )
    }
    
    public func set(_ value: T) -> AnimationProviderProtocol { setter.set(value) }
    public func set(from initial: T, _ value: T) -> AnimationProviderProtocol { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> AnimationProviderProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> AnimationProviderProtocol { setter.set(from: initial, values) }
    
}

extension AnimatePropertyMapper where R: UIKitPropertySettable, T: ScalableConvertable, T: Comparable {
    public subscript(_ range: Gradient<T>) -> AnimationProviderProtocol { setter.set(range) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: Animatable {
    
    private var setter: AnimatedPropertySetter<R, T, SwiftUIAnimate> {
        AnimatedPropertySetter(
            object: object,
            getter: {[object, keyPath] in object[keyPath: keyPath] },
            setter: {[object, keyPath] in if let v = $0 { object[keyPath: keyPath] = v } },
            scale: {
                var result = $0
                var lenght = $2.animatableData - $0.animatableData
                lenght.scale(by: $1)
                result.animatableData += lenght
                return result
            }
        )
    }
    
    public func set(_ value: T) -> AnimationProviderProtocol { setter.set(value) }
    public func set(from initial: T, _ value: T) -> AnimationProviderProtocol { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> AnimationProviderProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> AnimationProviderProtocol { setter.set(from: initial, values) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: Animatable, T: Comparable {
    public subscript(_ range: Gradient<T>) -> AnimationProviderProtocol { setter.set(range) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: VectorArithmetic {
    
    private var setter: AnimatedPropertySetter<R, T, SwiftUIAnimate> {
        AnimatedPropertySetter(
            object: object,
            getter: {[object, keyPath] in object[keyPath: keyPath] },
            setter: {[object, keyPath] in if let v = $0 { object[keyPath: keyPath] = v } },
            scale: {
                var lenght = $2 - $0
                lenght.scale(by: $1)
                return $0 + lenght
            }
        )
    }
    
    public func set(_ value: T) -> AnimationProviderProtocol { setter.set(value) }
    public func set(from initial: T, _ value: T) -> AnimationProviderProtocol { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> AnimationProviderProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> AnimationProviderProtocol { setter.set(from: initial, values) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: VectorArithmetic, T: Comparable {
    public subscript(_ range: Gradient<T>) -> AnimationProviderProtocol { setter.set(range) }
}

public protocol UIKitPropertySettable: class {}

extension UIKitPropertySettable {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: self)
    }
}

extension UIView: UIKitPropertySettable {}
extension CALayer: UIKitPropertySettable {}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: self)
    }
}

//extension NSLayoutConstraint {
//
//    public var ca: AnimatePropertyMapper<NSLayoutConstraint, CGFloat> {
//        AnimatePropertyMapper(object: self, keyPath: \.constant)
//    }
//
//}
