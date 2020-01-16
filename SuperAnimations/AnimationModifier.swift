//
//  AnimationModifier.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct AnimationModifier: AnimationProviderProtocol {
    public var asModifier: AnimationModifier { self }
    var modificators: AnimationOptions
    var animation: AnimationProviderProtocol
    var chain: Chainer<AnimationModifier> { Chainer(root: self) }
    
    public func start(with options: AnimationOptions?, _ completion: @escaping (Bool) -> ()) {
        animation.start(with: options ?? modificators, completion)
    }
    
    public func start() {
        start(with: nil, {_ in})
    }
    
}

//public struct AnyModifier<T> {
//    public let root: T
//    private let modification: (inout T) -> ()
//    
//    init(_ root: T, _ modification: @escaping (inout T) -> ()) {
//        
//    }
//}
