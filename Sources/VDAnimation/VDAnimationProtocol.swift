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
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate
    var modified: ModifiedAnimation { get }
    func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool)
}

public protocol ClosureAnimation: VDAnimationProtocol {
    init(_ closure: @escaping () -> Void)
}

extension VDAnimationProtocol {
    public var options: AnimationOptions { modified.options }
    public var modified: ModifiedAnimation { ModifiedAnimation(options: .empty, animation: self) }
    var chain: ValueChaining<Self> { ValueChaining(self) }
    
    public func set(position: AnimationPosition) {
			set(position: position, for: .empty, execute: true)
    }
    
    @discardableResult
    public func start(_ completion: ((Bool) -> Void)? = nil) -> AnimationDelegate {
        start(with: .empty, { completion?($0) })
    }
	
	@discardableResult
	public func start(_ completion: (() -> Void)? = nil) -> AnimationDelegate {
		start(with: .empty, { _ in completion?() })
	}
    
    public func set<F: BinaryFloatingPoint>(_ progress: F) {
			set(position: .progress(Double(progress)), for: .empty, execute: true)
    }
    
}

extension Optional: VDAnimationProtocol where Wrapped: VDAnimationProtocol {
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
        self?.start(with: options, completion) ?? .end
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
			self?.set(position: position, for: options, execute: execute)
    }
    
}
