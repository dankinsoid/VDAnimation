//
//  ModifiedAnimation.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public struct ModifiedAnimation: VDAnimationProtocol {
    
    public var modified: ModifiedAnimation { self }
    var options: AnimationOptions
    let animation: VDAnimationProtocol
    var chain: ValueChaining<ModifiedAnimation> { ValueChaining(self) }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
        animation.start(with: options.or(self.options), completion)
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
			animation.set(position: position, for: options.or(self.options), execute: execute)
    }
    
}
