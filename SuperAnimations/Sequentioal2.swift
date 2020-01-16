//
//  Sequentioal2.swift
//  SuperAnimations
//
//  Created by Daniil on 15.10.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation

public final class Sequential2: AnimationProtocol {
    
    public var description: SettedTiming = .default
    private var animations: [AnimationProtocol]
    
    public init(_ animations: [AnimationProtocol]) {
        self.animations = animations
    }
    
    public func calculate() -> Animate.Timing {
        Animate.Timing(duration: <#T##Double#>, curve: <#T##Animate.Timing.Curve#>)
    }
    
    public func set(parameters: AnimationParameters) {
        
    }
    
    public func start(_ completion: @escaping () -> ()) {
        
    }
    
}
