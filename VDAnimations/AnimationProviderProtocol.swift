//
//  AnimationProtocol.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public protocol AnimationProviderProtocol {
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ())
    var asModifier: AnimationModifier { get }
    func canSet(state: AnimationState, for options: AnimationOptions) -> Bool
    func set(state: AnimationState, for options: AnimationOptions)
}

public protocol AnimationClosureProviderProtocol: AnimationProviderProtocol {
    init(_ closure: @escaping () -> ())
}

extension AnimationProviderProtocol {
    public var modificators: AnimationOptions { asModifier.modificators }
    public var asModifier: AnimationModifier { AnimationModifier(modificators: .empty, animation: self) }
    var chain: Chainer<Self> { Chainer(root: self) }
    
    public func set(state: AnimationState) {
        set(state: state, for: .empty)
    }
    
}
