//
//  Pffff.swift
//  SuperAnimations
//
//  Created by Daniil on 28.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

protocol LazyAnimator: AnimatorProtocol {
    associatedtype A: AnimatorProtocol
    var animator: A { get }
}

public protocol AnimatorCollecton {
    var animatorsArray: [AnimatorProtocol] { get }
}

public struct AnimatorModifier<A: AnimatorProtocol>: LazyAnimator {
    public var progress: Double {
        get { animator.progress }
        set { animator.progress = newValue }
    }
    public var isRunning: Bool { animator.isRunning }
    public var state: UIViewAnimatingState { animator.state }
    public var timing: Animate.Timing { animator.timing }
    public var parameters: AnimationParameters
    var animator: A {
        _animator()
    }
//    var animator: T { _animator().copy(with: parameters) }
    let _animator: () -> A
    
    init(_ animator: @escaping () -> A, parameters: AnimationParameters) {
        self.parameters = parameters
        self._animator = animator
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        animator.start()
    }
    
    public func pause() {
        animator.pause()
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        animator.stop(at: position)
    }
    
    public func copy(with parameters: AnimationParameters) -> AnimatorModifier {
        
    }
    
}
