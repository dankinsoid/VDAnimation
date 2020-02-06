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
public struct AnimatePropertyMapper<R: AnimatedPropertyOwner, T, A: AnimationClosureProviderProtocol> {
    fileprivate let object: R
    private let scale: (T, Double, T) -> T
    private let keyPath: ReferenceWritableKeyPath<R.Object, T>
    private var getter: () -> T? { {[object, keyPath] in object.get(keyPath) } }
    private var setter: (T?) -> () { {[object, keyPath] in object.set($0, at: keyPath) } }
    
    fileprivate init(object: R, keyPath: ReferenceWritableKeyPath<R.Object, T>, scale: @escaping (T, Double, T) -> T) {
        self.keyPath = keyPath
        self.object = object
        self.scale = scale
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D, A> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D, A>(
            object: object,
            keyPath: kp,
            scale: { f, _, _ in f }
        )
    }
    
    public subscript<D: ScalableConvertable>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D, A> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D, A>(
            object: object,
            keyPath: kp,
            scale: { D.init(scaleData: $0.scaleData + ($2.scaleData - $0.scaleData).scaled(by: $1)) }
        )
    }
    
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public subscript<D: Animatable>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D, A> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D, A>(
            object: object,
            keyPath: kp,
            scale: {
                var result = $0
                var lenght = $2.animatableData - $0.animatableData
                lenght.scale(by: $1)
                result.animatableData += lenght
                return result
            }
        )
    }
    
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public subscript<D: VectorArithmetic>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D, A> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D, A>(
            object: object,
            keyPath: kp,
            scale: {
                var lenght = $2 - $0
                lenght.scale(by: $1)
                return $0 + lenght
            }
        )
    }
    
    public func set(_ value: T) -> AnimationProviderProtocol {
        return _set(from: nil, value)
    }
    
    public func set(from initial: T, _ value: T) -> AnimationProviderProtocol {
        return _set(from: initial, value)
    }
    
    private func _set(from initial: T?, _ value: T) -> AnimationProviderProtocol {
        return PropertyAnimator(
            from: {[getter] in initial ?? getter() },
            getter: getter,
            setter: setter,
            scale: scale,
            value: value,
            animatorType: A.self
        )
    }
    
    public func set(_ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol {
        set([a, b] + values)
    }
    
    public func set(_ values: [T]) -> AnimationProviderProtocol {
        guard values.count > 1 else {
            return Sequential(values.map { set($0) })
        }
        var array = values
        var animations = [set(values[0])]
        array.removeFirst()
        animations += sequential(from: values[0], array)
        return Sequential(animations)
    }
    
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> AnimationProviderProtocol {
        set(from: initial, [a, b] + values)
    }
    
    public func set(from initial: T, _ values: [T]) -> AnimationProviderProtocol {
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

extension AnimatePropertyMapper where T: Comparable {
    
    public func set(_ range: ClosedRange<T>) -> AnimationProviderProtocol {
        set(from: range.lowerBound, range.upperBound)
    }
}

@dynamicMemberLookup
public struct AnimatedPropertyMaker<R> {
    private var object: R
    
    fileprivate init(object: R) {
        self.object = object
    }
}

extension AnimatedPropertyMaker where R: UIKitPropertySettable {
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatePropertyMapper<ClassAnimatedPropertyOwner<R>, D, Animate> {
        return AnimatePropertyMapper<ClassAnimatedPropertyOwner<R>, D, Animate>(
            object: ClassAnimatedPropertyOwner(object: object),
            keyPath: keyPath,
            scale: { f, _, _ in f }
        )
    }
    
}

extension AnimatedPropertyMaker where R: View {
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatePropertyMapper<ViewAnimatedPropertyOwner<R>, D, SwiftUIAnimate> {
        return AnimatePropertyMapper<ViewAnimatedPropertyOwner<R>, D, SwiftUIAnimate>(
            object: ViewAnimatedPropertyOwner(object: object),
            keyPath: keyPath,
            scale: { f, _, _ in f }
        )
    }
    
}

public protocol AnimatedPropertyOwner {
    associatedtype Object
    func get<T>(_ keyPath: ReferenceWritableKeyPath<Object, T>) -> T?
    func set<T>(_ value: T?, at keyPath: ReferenceWritableKeyPath<Object, T>)
}

public struct ClassAnimatedPropertyOwner<Object: AnyObject>: AnimatedPropertyOwner {
    fileprivate weak var object: Object?
    
    public func get<T>(_ keyPath: ReferenceWritableKeyPath<Object, T>) -> T? {
        object?[keyPath: keyPath]
    }
    
    public func set<T>(_ value: T?, at keyPath: ReferenceWritableKeyPath<Object, T>) {
        guard let value = value else { return }
        object?[keyPath: keyPath] = value
    }
    
}

public struct ViewAnimatedPropertyOwner<Object: View>: AnimatedPropertyOwner {
    fileprivate let object: Object
    
    public func get<T>(_ keyPath: ReferenceWritableKeyPath<Object, T>) -> T? {
        object[keyPath: keyPath]
    }
    
    public func set<T>(_ value: T?, at keyPath: ReferenceWritableKeyPath<Object, T>) {
        guard let value = value else { return }
        object[keyPath: keyPath] = value
    }
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
