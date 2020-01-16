//
//  StateWrapper.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
@dynamicMemberLookup
public struct SwiftUIPropertySetter<R, T> {
    private let object: R
    private let keyPath: ReferenceWritableKeyPath<R, T>
    
    public func set(_ value: T) -> Animate {
        let kp = keyPath
        return Animate {[object] in
            object[keyPath: kp] = value
        }
    }
    
    fileprivate init(object: R, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.object = object
        self.keyPath = keyPath
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> SwiftUIPropertySetter<R, D> {
        return SwiftUIPropertySetter<R, D>(object: object, keyPath: self.keyPath.appending(path: keyPath))
    }
    
}

@available(iOS 13.0, macOS 10.15, *)
@dynamicMemberLookup
public struct SwiftUIPropertyMaker<R> {
    private let object: R
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> SwiftUIPropertySetter<R, D> {
        return SwiftUIPropertySetter<R, D>(object: object, keyPath: keyPath)
    }
    
}

@available(iOS 13.0, macOS 10.15, *)
extension View {
    
    public var ca: SwiftUIPropertyMaker<Self> {
        return SwiftUIPropertyMaker(object: self)
    }
    
}
