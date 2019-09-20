//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Sequential {
    public var isRunning: Bool = false
    public var progress: Double = 0
    private var animations: [AnimatorProtocol]
    private var currentAnimation = 0
    
    public init(_ animations: [AnimatorProtocol]) {
        self.animations = animations
    }
    
    public init(_ animations: AnimatorProtocol...) {
        self.animations = animations
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func duration(_ value: Double) -> Sequential {
        return self
    }
    
    public func start(_ completion: ((UIViewAnimatingPosition) -> ())? = nil) {
        guard !isRunning else {
            return
        }
        _start(completion)
    }
    
    private func _start(_ completion: ((UIViewAnimatingPosition) -> ())?) {
        guard !animations.isEmpty, currentAnimation < animations.count else {
            isRunning = false
            completion?(.end)
            return
        }
        isRunning = true
        animations[currentAnimation].start {[weak self] state in
            guard let it = self else { return }
            guard state == .end else {
                it.isRunning = false
                completion?(state)
                return
            }
            it.currentAnimation += 1
            it._start(completion)
        }
    }
    
    public func pause() {
        defer { isRunning = false }
        guard !animations.isEmpty, currentAnimation < animations.count, isRunning else {
            return
        }
        animations[currentAnimation].pause()
    }
    
    public func stop() {
        defer { isRunning = false }
        guard !animations.isEmpty, currentAnimation < animations.count else {
            return
        }
        animations[currentAnimation].stop()
    }

}
