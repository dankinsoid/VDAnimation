//
//  VDViewAnimator.swift
//  SuperAnimations
//
//  Created by Daniil on 21.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

class VDViewAnimator: UIViewPropertyAnimator {
    private var observers: [UUID: (UIViewAnimatingPosition) -> ()] = [:]
    var reverseOnComplete = false
    var isPaused = false
    
    var position: UIViewAnimatingPosition {
        switch fractionComplete {
        case 0: return .start
        case 1: return .end
        default: return .current
        }
    }
    
    deinit {
        if state != .stopped, !isRunning {
            if reverseOnComplete {
                super.stopAnimation(false)
                finishAnimation(at: .start)
            } else {
                super.stopAnimation(true)
            }
        }
    }
    
    override init(duration: TimeInterval, timingParameters parameters: UITimingCurveProvider) {
        super.init(duration: duration, timingParameters: parameters)
        pausesOnCompletion = true
    }
    
    func pause() {
        super.pauseAnimation()
        isPaused = true
    }
    
    func stop() {
        super.stopAnimation(false)
    }
    
    override func stopAnimation(_ withoutFinishing: Bool) {
        super.stopAnimation(withoutFinishing)
        notify()
    }
    
    override func pauseAnimation() {
        super.pauseAnimation()
        notify()
        if reverseOnComplete {
            fractionComplete = 0
        }
    }
    
    func startAnimation(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        let id = UUID()
        observers[id] = {[weak self] in
            completion($0)
            self?.removeCompletion(id: id)
        }
        startAnimation()
    }
    
    private func notify() {
        let value = position
        observers.forEach { $0.value(value) }
    }
    
    func removeCompletion(id: UUID) {
        observers[id] = nil
    }
    
    override func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        let id = UUID()
        observers[id] = completion
    }
    
}
