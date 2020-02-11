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
    var chain: ValueChaining<AnimationModifier> { ValueChaining(self) }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        animation.start(with: options.or(modificators), completion)
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        animation.set(state: state, for: options.or(modificators))
    }
    
}
