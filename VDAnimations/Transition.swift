//
//  Transition.swift
//  CA
//
//  Created by Daniil on 01.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct Transition: AnimationProviderProtocol {
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        UIView.transition(
            with: <#T##UIView#>,
            duration: <#T##TimeInterval#>,
            options: UIView.AnimationOptions,
            animations: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>,
            completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>
        )
    }
    
    public func canSet(state: AnimationState, for options: AnimationOptions) -> Bool {
        <#code#>
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        UIPercentDrivenInteractiveTransition()
    }
    
}

class Tr: UIPercentDrivenInteractiveTransition {
    
}
