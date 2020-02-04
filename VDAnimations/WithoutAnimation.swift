//
//  WithoutAnimation.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct WithoutAnimation: AnimationClosureProviderProtocol {
    
    public var asModifier: AnimationModifier { AnimationModifier(modificators: AnimationOptions.empty.chain.duration[.absolute(0)], animation: self) }
    
    private let block: () -> ()
    
    public init(_ closure: @escaping () -> ()) {
        block = closure
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        execute(completion)
    }
    
    public func canSet(state: AnimationState) -> Bool {
        if case .end = state { return true }
        return false
    }
    
    public func set(state: AnimationState) {
        if case .end = state {
            execute({_ in })
        }
    }
    
    private func execute(_ completion: @escaping (Bool) -> ()) {
        UIView.performWithoutAnimation(block)
        completion(true)
    }
    
}
