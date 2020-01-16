//
//  Animate2.swift
//  SuperAnimations
//
//  Created by Daniil on 15.10.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Animate2: AnimationProtocol {
    
    public var description: SettedTiming = .default
    private var animator = VDViewAnimator()
    private let animation: () -> ()
    
    public init(_ animation: @escaping () -> ()) {
        self.animation = animation
    }
    
    public func calculate() -> Animate.Timing {
        Animate.Timing(duration: description.duration?.fixed ?? 0, curve: description.curve ?? .linear)
    }
    
    public func set(parameters: AnimationParameters) {
        let timing = parameters.timing
        let provider = VDTimingProvider(bezier: timing.curve, spring: nil)
        animator = VDViewAnimator(
            duration: timing.duration,
            timingParameters: provider
        )
        set(options: parameters.options)
    }
    
    private func set(options: Animate.Options) {
        animator.isInterruptible = options.isInterruptible
        animator.isManualHitTestingEnabled = options.isManualHitTestingEnabled
        if options.isReversed {
            animator.fractionComplete = 1 - animator.fractionComplete
        }
        animator.isReversed = options.isReversed
        animator.reverseOnComplete = options.restoreOnFinish
        if animator.state != .active {
            animator.isUserInteractionEnabled = options.isUserInteractionEnabled
            animator.scrubsLinearly = options.scrubsLinearly
        }
    }
    
    public func start(_ completion: @escaping () -> ()) {
        animator.startAnimation { _ in
            completion()
        }
    }
    
    
}
