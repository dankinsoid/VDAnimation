//
//  AnimationProtocol.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public protocol VDAnimationProtocol {
    @discardableResult
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate
    var modified: ModifiedAnimation { get }
    func set(position: AnimationPosition, for options: AnimationOptions)
}

public protocol ClosureAnimation: VDAnimationProtocol {
    init(_ closure: @escaping () -> ())
}

extension VDAnimationProtocol {
    public var options: AnimationOptions { modified.options }
    public var modified: ModifiedAnimation { ModifiedAnimation(options: .empty, animation: self) }
    var chain: ValueChaining<Self> { ValueChaining(self) }
    
    public func set(position: AnimationPosition) {
        set(position: position, for: .empty)
    }
    
    @discardableResult
    public func start(_ completion: ((Bool) -> ())? = nil) -> AnimationDelegate {
        start(with: .empty, { completion?($0) })
    }
    
    public func set<F: BinaryFloatingPoint>(_ progress: F) {
        set(position: .progress(Double(progress)), for: .empty)
    }
    
}

extension Optional: VDAnimationProtocol where Wrapped: VDAnimationProtocol {
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        self?.start(with: options, completion) ?? .end
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        self?.set(position: position, for: options)
    }
    
}
