//
//  Parallel.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public struct Parallel {
    public var isRunning: Bool = false
    public var progress: Double = 0
    
    private var animations: [AnimatorProtocol]
    
    public init(_ animations: [AnimatorProtocol]) {
        self.animations = animations
    }
    
    public init(_ animations: AnimatorProtocol...) {
        self = Parallel(animations)
    }
    
    public init(@AnimatorBuilder _ animations: () -> ()) {
        animations()
        self = Parallel()
    }
    
    public init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self = Parallel(animations())
    }
    
    public init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self = Parallel(animations())
    }
    
    public func duration(_ value: Double) -> Parallel {
        return self
    }
    
    public func start(_ completion: ((UIViewAnimatingPosition) -> ())? = nil) {
        animations.forEach { $0.start(nil) }
    }
    
    public func pause() {
        animations.forEach { $0.pause() }
    }
    
    public func stop() {
        animations.forEach { $0.stop() }
    }
    
}
