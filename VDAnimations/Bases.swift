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
public struct AnimatedPropertySetter<R, T> {
    private let object: R
    private let keyPath: ReferenceWritableKeyPath<R, T>
    
    fileprivate init(object: R, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.object = object
        self.keyPath = keyPath
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatedPropertySetter<R, D> {
        return AnimatedPropertySetter<R, D>(object: object, keyPath: self.keyPath.appending(path: keyPath))
    }
    
}

extension AnimatedPropertySetter where R: AnimatedPropertySettable, T: ScalableConvertable {
    
    public func set(_ a: T, _ b: T, _ values: T...) -> Sequential {
        set([a, b] + values)
    }
    
    public func set(_ values: [T]) -> Sequential {
        set(from: object[keyPath: keyPath], values)
    }
    
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> Sequential {
        set(from: initial, [a, b] + values)
    }
    
    public func set(_ value: T) -> PropertyAnimator<T, Animate> {
        _set(from: object[keyPath: keyPath], value)
    }
    
    public func set(from initial: T, _ values: [T]) -> Sequential {
        guard values.count > 1 else {
            return Sequential([_set(from: initial, initial)])
        }
        var array = [initial] + values
        var from = initial
        var animations: [PropertyAnimator<T, Animate>] = []
        while !array.isEmpty {
            let second = array.removeFirst()
            animations.append(_set(from: from, second))
            from = second
        }
        return Sequential(animations)
    }
    
    private func _set(from initial: T, _ value: T) -> PropertyAnimator<T, Animate> {
        let kp = keyPath
        return PropertyAnimator(
            from: initial,
            getter: {[object] in object[keyPath: kp] },
            setter: {[object] in
                guard let v = $0 else { return }
                object[keyPath: kp] = v
            },
            value: value,
            animatorType: Animate.self
        )
    }
    
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatedPropertySetter where T: Animatable, R: View {
    
    public func set(_ a: T, _ b: T, _ values: T...) -> Sequential {
        set([a, b] + values)
    }
    
    public func set(_ values: [T]) -> Sequential {
        set(from: object[keyPath: keyPath], values)
    }
    
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> Sequential {
        set(from: initial, [a, b] + values)
    }
    
    public func set(_ value: T) -> PropertyAnimator<T, SwiftUIAnimate> {
        _set(from: object[keyPath: keyPath], value)
    }
    
    public func set(from initial: T, _ values: [T]) -> Sequential {
        guard values.count > 1 else {
            return Sequential([_set(from: initial, initial)])
        }
        var array = [initial] + values
        var from = initial
        var animations: [PropertyAnimator<T, SwiftUIAnimate>] = []
        while !array.isEmpty {
            let second = array.removeFirst()
            animations.append(_set(from: from, second))
            from = second
        }
        return Sequential(animations)
    }
    
    private func _set(from initial: T, _ value: T) -> PropertyAnimator<T, SwiftUIAnimate> {
        let kp = keyPath
        return PropertyAnimator(
            from: initial,
            getter: {[object] in object[keyPath: kp] },
            setter: {[object] in
                guard let v = $0 else { return }
                object[keyPath: kp] = v
            },
            value: value,
            animatorType: SwiftUIAnimate.self
        )
    }
    
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimatedPropertySetter where T: VectorArithmetic, R: View {
    
    public func set(_ a: T, _ b: T, _ values: T...) -> Sequential {
        set([a, b] + values)
    }
    
    public func set(_ values: [T]) -> Sequential {
        set(from: object[keyPath: keyPath], values)
    }
    
    public func set(from initial: T, _ a: T, _ b: T, _ values: T...) -> Sequential {
        set(from: initial, [a, b] + values)
    }
    
    public func set(_ value: T) -> PropertyAnimator<T, SwiftUIAnimate> {
        _set(from: nil, value)
    }
    
    public func set(from initial: T, _ values: [T]) -> Sequential {
        guard values.count > 1 else {
            return Sequential([_set(from: initial, initial)])
        }
        var array = [initial] + values
        var from = initial
        var animations: [PropertyAnimator<T, SwiftUIAnimate>] = []
        while !array.isEmpty {
            let second = array.removeFirst()
            animations.append(_set(from: from, second))
            from = second
        }
        return Sequential(animations)
    }
    
    private func _set(from initial: T?, _ value: T) -> PropertyAnimator<T, SwiftUIAnimate> {
        let kp = keyPath
        return PropertyAnimator(
            from: initial,
            getter: {[object] in object[keyPath: kp] },
            setter: {[object] in
                guard let v = $0 else { return }
                object[keyPath: kp] = v
            },
            value: value,
            animatorType: SwiftUIAnimate.self
        )
    }
    
}

@dynamicMemberLookup
public struct AnimatedPropertyMaker<R> {
    private var object: R
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatedPropertySetter<R, D> {
        return AnimatedPropertySetter<R, D>(object: object, keyPath: keyPath)
    }
    
}

public protocol AnimatedPropertySettable: class {}

extension AnimatedPropertySettable {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: self)
    }
}

extension UIView: AnimatedPropertySettable {}
extension CALayer: AnimatedPropertySettable {}

extension View {
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: self)
    }
}
