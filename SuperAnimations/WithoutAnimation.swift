//
//  NoAnimation.swift
//  SuperAnimations
//
//  Created by crypto_user on 25/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class WithoutAnimation: AnimatorProtocol {
    public var progress: Double {
        get { 1 }
        set {
            if newValue > 0 {
                block()
            }
        }
    }
    public let isRunning: Bool = false
    public let state: UIViewAnimatingState = .inactive
    public var parameters: AnimationParameters = .default
    public let timing = Animate.Timing.default
    let block: () -> ()
    
    public init(_ block: @escaping () -> ()) {
        self.block = block
        parameters.settedTiming.duration = .absolute(0)
    }
    
    public func copy(with parameters: AnimationParameters) -> WithoutAnimation {
        let result = WithoutAnimation(block)
        result.parameters.completion = parameters.completion
        return result
    }
    
    public func pause() {}
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        UIView.performWithoutAnimation(block)
        parameters.completion(.end)
        completion(.end)
    }
    
    public func stop(at position: UIViewAnimatingPosition) {}
    
}
