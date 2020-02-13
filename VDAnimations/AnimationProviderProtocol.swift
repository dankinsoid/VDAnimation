//
//  AnimationProtocol.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public protocol VDAnimationProtocol {
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate
    var modified: ModifiedAnimation { get }
    func set(state: AnimationState, for options: AnimationOptions)
}

public protocol AnimationClosureProviderProtocol: VDAnimationProtocol {
    init(_ closure: @escaping () -> ())
}

extension VDAnimationProtocol {
    public var options: AnimationOptions { modified.options }
    public var modified: ModifiedAnimation { ModifiedAnimation(options: .empty, animation: self) }
    var chain: ValueChaining<Self> { ValueChaining(self) }
    
    public func set(state: AnimationState) {
        set(state: state, for: .empty)
    }
    
    @discardableResult
    public func start(_ completion: ((Bool) -> ())? = nil) -> AnimationDelegate {
        start(with: .empty, { completion?($0) })
    }
    
}

extension Optional: VDAnimationProtocol where Wrapped: VDAnimationProtocol {
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        self?.start(with: options, completion) ?? AnimationDelegate({_ in })
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        self?.set(state: state, for: options)
    }
    
}
