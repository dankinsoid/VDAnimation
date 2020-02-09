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
    
    deinit {
        observing?.invalidate()
        finishAnimation(at: .end)
    }
    
    override func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
        guard state != .inactive else { return }
        if state != .stopped {
            stopAnimation(false)
        }
        if state == .stopped {
            super.finishAnimation(at: finalPosition)
        }
    }
    
    override func startAnimation() {
        observeRunning()
        super.startAnimation()
    }
    
    override func startAnimation(afterDelay delay: TimeInterval) {
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
        super.addCompletion(completion)
    }
    
}
