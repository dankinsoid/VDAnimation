//
//  Bases.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

@dynamicMemberLookup
public struct AnimatedPropertySetter<R: AnyObject, T> {
    private weak var object: R?
    private let keyPath: ReferenceWritableKeyPath<R, T>
    
    public func set(_ value: T) -> Animator {
        let kp = keyPath
        return Animator {[weak object] in
            object?[keyPath: kp] = value
        }
    }
    
    fileprivate init(object: R?, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.object = object
        self.keyPath = keyPath
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> AnimatedPropertySetter<R, D> {
        return AnimatedPropertySetter<R, D>(object: object, keyPath: self.keyPath.appending(path: keyPath))
    }
    
}

@dynamicMemberLookup
public struct AnimatedPropertyMaker<R: AnyObject> {
    private weak var object: R?
    
    fileprivate init(object: R?) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> AnimatedPropertySetter<R, D> {
        return AnimatedPropertySetter<R, D>(object: object, keyPath: keyPath)
    }
    
}


@dynamicMemberLookup
public final class AnimatedPropertyValues<R: AnyObject> {
    private var object: R
    private var values: [PartialKeyPath<R>: Any] = [:]
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> D {
        get {
            return object[keyPath: keyPath]
        }
        set {
            values[keyPath] = newValue
        }
    }
    
}

public protocol AnimatedPropertySettable: class {}

extension AnimatedPropertySettable {
    
    public var ca: AnimatedPropertyMaker<Self> {
        return AnimatedPropertyMaker(object: self)
    }
    
    public var animate: AnimatedPropertyValues<Self> {
        return AnimatedPropertyValues(object: self)
    }
    
}

extension UIView: AnimatedPropertySettable {}
extension CALayer: AnimatedPropertySettable {}
