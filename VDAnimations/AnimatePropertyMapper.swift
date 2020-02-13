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
    fileprivate let object: () -> R?
    private let keyPath: ReferenceWritableKeyPath<R, T>
    private let animatable: PropertyAnimatable
    
    init(object: @escaping () -> R?, animatable: PropertyAnimatable, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.keyPath = keyPath
        self.object = object
        self.animatable = animatable
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatePropertyMapper<R, D> {
        let kp = self.keyPath.appending(path: keyPath)
        return AnimatePropertyMapper<R, D>(object: object, animatable: animatable, keyPath: kp)
    }
    
}

private struct AnimatedPropertySetter<R, T, A: ClosureAnimation> {
    fileprivate let object: () -> R?
    private let scale: (T, Double, T) -> T
    private let keyPath: ReferenceWritableKeyPath<R, T>
    private let animatable: PropertyAnimatable
    
    fileprivate init(object: @escaping () -> R?, keyPath: ReferenceWritableKeyPath<R, T>,  animatable: PropertyAnimatable, scale: @escaping (T, Double, T) -> T) {
        self.keyPath = keyPath
        self.object = object
        self.scale = scale
        self.animatable = animatable
    }
    
    func set(_ value: T) -> PropertyAnimator<R, A> {
        return _set(from: nil, value)
    }
    
    func set(from initial: T, _ value: T) -> PropertyAnimator<R, A> {
        return _set(from: initial, value)
    }
    
     func _set(from initial: T?, _ value: T) -> PropertyAnimator<R, A> {
        PropertyAnimator(
            PropertyOwner(
                from: initial,
                getter: { self.object()?[keyPath: self.keyPath] },
                setter: {
                    guard let v = $0, let object = self.object() else { return }
                    object[keyPath: self.keyPath] = v
                    (object as? NSLayoutConstraint)?.didUpdate()
                },
                scale: scale,
                value: value
            ).asAnimatable.union(animatable),
            get: object
        )
    }
    
    func set(_ a: T, _ b: T, _ values: [T]) -> VDAnimationProtocol {
        set([a, b] + values)
    }
    
    func set(_ values: [T]) -> VDAnimationProtocol {
        guard values.count > 1 else {
            return Sequential(values.map { set($0) })
        }
        var array = values
        var animations = [set(values[0]) as VDAnimationProtocol]
        array.removeFirst()
        animations += sequential(from: values[0], array)
        return Sequential(animations)
    }
    
    func set(from initial: T, _ a: T, _ b: T, _ values: [T]) -> VDAnimationProtocol {
        set(from: initial, [a, b] + values)
    }
    
    func set(from initial: T, _ values: [T]) -> VDAnimationProtocol {
        Sequential(sequential(from: initial, values))
    }
    
    private func sequential(from initial: T, _ values: [T]) -> [VDAnimationProtocol] {
        guard values.count > 0 else {
            return [set(from: initial, initial)]
        }
        var array = values
        var from = initial
        var animations: [VDAnimationProtocol] = []
        while !array.isEmpty {
            let second = array.removeFirst()
            animations.append(set(from: from, second))
            from = second
        }
        return animations
    }
    
    fileprivate func set(_ range: Gradient<T>) -> PropertyAnimator<R, A> {
        set(from: range.from, range.to)
    }
    
}

@dynamicMemberLookup
public struct AnimatedPropertyMaker<R> {
    private var object: () -> R?
    
    fileprivate init(object: @escaping () -> R?) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatePropertyMapper<R, D> {
        AnimatePropertyMapper(object: object, animatable: .empty, keyPath: keyPath)
    }
    
}

extension AnimatePropertyMapper where R: UIKitPropertySettable, T: ScalableConvertable {
    
    private var setter: AnimatedPropertySetter<R, T, Animate> {
        AnimatedPropertySetter(
            object: object,
            keyPath: keyPath,
            animatable: animatable,
            scale: { T.init(scaleData: $0.scaleData + ($2.scaleData - $0.scaleData).scaled(by: $1)) }
        )
    }
    
    public func set(_ value: T) -> PropertyAnimator<R, Animate> { setter.set(value) }
    public func set(from initial: T, _ value: T) -> PropertyAnimator<R, Animate> { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> VDAnimationProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> VDAnimationProtocol { setter.set(from: initial, values) }
    public subscript(_ range: Gradient<T>) -> PropertyAnimator<R, Animate> { setter.set(range) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: Animatable {
    
    private var setter: AnimatedPropertySetter<R, T, SwiftUIAnimate> {
        AnimatedPropertySetter(
            object: object,
            keyPath: keyPath,
            animatable: animatable,
            scale: {
                var result = $0
                var lenght = $2.animatableData - $0.animatableData
                lenght.scale(by: $1)
                result.animatableData += lenght
                return result
            }
        )
    }
    
    public func set(_ value: T) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(value) }
    public func set(from initial: T, _ value: T) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> VDAnimationProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> VDAnimationProtocol { setter.set(from: initial, values) }
    public subscript(_ range: Gradient<T>) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(range) }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatePropertyMapper where R: View, T: VectorArithmetic {
    
    private var setter: AnimatedPropertySetter<R, T, SwiftUIAnimate> {
        AnimatedPropertySetter(
            object: object,
            keyPath: keyPath,
            animatable: animatable,
            scale: {
                var lenght = $2 - $0
                lenght.scale(by: $1)
                return $0 + lenght
            }
        )
    }
    
    public func set(_ value: T) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(value) }
    public func set(from initial: T, _ value: T) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(from: initial, value) }
    public func set(_ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(a, b, values) }
    public func set(_ values: [T]) -> VDAnimationProtocol { setter.set(values) }
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> VDAnimationProtocol { setter.set(from: initial, a, b, values) }
    public func set(from initial: T, _ values: [T]) -> VDAnimationProtocol { setter.set(from: initial, values) }
    public subscript(_ range: Gradient<T>) -> PropertyAnimator<R, SwiftUIAnimate> { setter.set(range) }
}

public protocol UIKitPropertySettable: class {}

extension UIKitPropertySettable {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: {[weak self] in self })
    }
}

extension UIView: UIKitPropertySettable {}
extension CALayer: UIKitPropertySettable {}

extension NSLayoutConstraint: UIKitPropertySettable {
    public var ca: AnimatedPropertyMaker<NSLayoutConstraint> {
        return AnimatedPropertyMaker(object: { self })
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: { self })
    }
}

extension NSLayoutConstraint {

    func didUpdate() {
        guard isActive else { return }
        let view1 = firstItem as? UIView ?? (firstItem as? UILayoutGuide)?.owningView
        let view2 = secondItem as? UIView ?? (secondItem as? UILayoutGuide)?.owningView
        if let parent = view1?.commonSuper(with: view2) {
            parent.layoutIfNeeded()
        } else {
            (view1?.superview ?? view1)?.layoutIfNeeded()
            guard view1 !== view2 else { return }
            (view2?.superview ?? view2)?.layoutIfNeeded()
        }
    }

}

extension UIView {
    
    fileprivate func commonSuper(with: UIView?) -> UIView? {
        guard let view = with else { return nil }
        if isDescendant(of: view) { return view.superview ?? view }
        return commonParent(with: view)
    }
    
    private func commonParent(with view: UIView) -> UIView? {
        if view.isDescendant(of: self) { return superview ?? self }
        return superview?.commonParent(with: view)
    }
    
}
