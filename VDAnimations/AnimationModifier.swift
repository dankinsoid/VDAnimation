//
//  ModifiedAnimation.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct ModifiedAnimation: VDAnimationProtocol {
    
    public var modified: ModifiedAnimation { self }
    var options: AnimationOptions
    var animation: VDAnimationProtocol
    var chain: ValueChaining<ModifiedAnimation> { ValueChaining(self) }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        animation.start(with: options.or(options), completion)
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        animation.set(position: position, for: options.or(options))
    }
    
}
