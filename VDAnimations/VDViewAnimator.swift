//
//  VDViewAnimator.swift
//  SuperAnimations
//
//  Created by Daniil on 21.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

class VDViewAnimator: UIViewPropertyAnimator {
    
    private var completions: [(UIViewAnimatingPosition) -> Void] = []
    private var observing: NSKeyValueObservation?
    private var prevRunning = false
    private var hasCalledCompletions = false
    
    deinit {
        observing?.invalidate()
        finishAnimation(at: .current)
    }
    
    override func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
        guard position != .inactive else { return }
        if position != .stopped {
            stopAnimation(false)
        }
        if position == .stopped {
            super.finishAnimation(at: finalPosition)
        } else {
            fractionComplete = 1
        }
    }
    
    override func startAnimation() {
        hasCalledCompletions = false
        observeRunning()
        super.startAnimation()
    }
    
    override func startAnimation(afterDelay delay: TimeInterval) {
        hasCalledCompletions = false
        observeRunning()
        super.startAnimation(afterDelay: delay)
    }
    
    private func observeRunning() {
        guard pausesOnCompletion, observing == nil else { return }
        observing = observe(\.isRunning) {[weak self] (_, change) in
            defer { self?.prevRunning = self?.isRunning ?? false }
            guard let it = self, it.pausesOnCompletion, it.isRunning == false, it.prevRunning == true else { return }
            it.observing?.invalidate()
            it.observing = nil
            it.hasCalledCompletions = true
            it.completions.forEach {
                switch it.fractionComplete {
                case 1:  $0(it.isReversed ? .start : .end)
                default: $0(.current)
                }
            }
        }
    }
    
    override func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completions.append(completion)
        super.addCompletion {[weak self] b in
            guard self?.hasCalledCompletions == false else { return }
            completion(b)
        }
    }
    
}
