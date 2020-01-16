//
//  Chainer.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

@dynamicMemberLookup
struct Chainer<T> {
    let root: T
    
    subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> Mapper<T, V> {
        Mapper(keyPath: keyPath, root: root)
    }
}

@dynamicMemberLookup
struct Mapper<T, V> {
    
    let keyPath: WritableKeyPath<T, V>
    let root: T
    
    subscript(_ value: V) -> T {
        var result = root
        result[keyPath: keyPath] = value
        return result
    }
    
    subscript<A>(dynamicMember keyPath: WritableKeyPath<V, A>) -> Mapper<T, A> {
        Mapper<T, A>(keyPath: self.keyPath.appending(path: keyPath), root: root)
    }
    
}
