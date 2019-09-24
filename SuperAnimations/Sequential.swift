//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Sequential: AnimatorProtocol {
    public var parameters: AnimationParameters = .default
    public var state: UIViewAnimatingState { currentAnimation?.state ?? .inactive }
    public var isRunning: Bool { currentAnimation?.isRunning ?? false }
    public var progress: Double {
        get { getProgress() }
        set { setProgress(newValue) }
    }
    private var animations: [AnimatorProtocol]
    private var currentIndex = 0
    private var firstStart = true
    private var currentAnimation: AnimatorProtocol? {
        if currentIndex < animations.count, currentIndex >= 0 {
            return isReversed ? animations[currentIndex].reversed() : animations[currentIndex]
        }
        return nil
    }
    
    init(_ animations: [AnimatorProtocol], parameters: AnimationParameters) {
        self.animations = animations
        self.parameters = parameters
    }
    
    public convenience init(_ animations: [AnimatorProtocol]) {
        self.init(animations, parameters: .default)
    }
    
    public convenience init(_ animations: AnimatorProtocol...) {
        self.init(animations)
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        configureChildren()
        guard !isRunning else {
            let c = parameters.completion
            parameters.completion = {[weak self] in
                c($0)
                completion($0)
                self?.parameters.completion = c
            }
            return
        }
        if isReversed {
            (0..<(animations.count)).forEach {
                animations[$0].progress = 1
            }
        }
        _start(completion)
    }
    
    private func _start(_ completion: ((UIViewAnimatingPosition) -> ())?) {
        guard !animations.isEmpty, currentIndex < animations.count else {
            parameters.completion(.end)
            completion?(.end)
            return
        }
        currentAnimation?.start {
            guard $0 != .current else {
                self.parameters.completion($0)
                completion?($0)
                return
            }
            self.currentIndex += 1
            self._start(completion)
        }
    }
    
    public func pause() {
        currentAnimation?.pause()
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        currentAnimation?.stop(at: position)
        switch position {
        case .start:    currentIndex = 0
        case .end:      currentIndex = animations.count
        default:        break
        }
    }
    
    public func copy(with parameters: AnimationParameters) -> Sequential {
        return Sequential(animations, parameters: parameters)
    }
    
    private func getProgress() -> Double {
        configureChildren()
        guard animations.count != 1 else { return currentAnimation?.progress ?? 0 }
        guard !animations.isEmpty else { return 0 }
        guard currentIndex < animations.count else { return 1 }
        let full = animations.reduce(0, { $0 + $1.timing.duration })
        guard full > 0 else { return currentAnimation?.progress ?? 1 }
        var current = (currentAnimation?.progress ?? 0) * (currentAnimation?.timing.duration ?? 0)
        current += animations.prefix(currentIndex).reduce(0, { $0 + $1.timing.duration })
        return current / full
    }
    
    private func setProgress(_ value: Double) {
        guard !animations.isEmpty else { return }
        configureChildren()
        let full = animations.reduce(0, { $0 + $1.timing.duration })
        guard full > 0 else {
            currentIndex = max(0, min(currentIndex, animations.count - 1))
            animations[currentIndex].progress = value
            print(value)
            return
        }
        let expected = value * full
        var i = 0
        var dur = 0.0
        while i < animations.count {
            guard dur + animations[i].timing.duration < expected else { break }
            dur += animations[i].timing.duration
            i += 1
        }
        let newValue = max(0, min(1, (expected - dur) / animations[i].timing.duration))
        guard i != currentIndex else {
            print(i, newValue)
            animations[i].progress = newValue
            return
        }
        currentIndex = i
        animations[i].stop(at: .current)
        if i < animations.count - 1 {
            for j in (i + 1)..<animations.count {
                animations[j].progress = 0
                animations[j].stop(at: .start)
            }
        }
        if i > 0 {
            for j in 0..<i {
                animations[j].progress = 1
                animations[j].stop(at: .end)
            }
        }
        guard i < animations.count else {
            print("last", 1)
            return
        }
        print(i, newValue)
        animations[i].progress = newValue
    }
    
    private func configureChildren() {
        guard firstStart else { return }
        setDuration()
        setCurve()
        firstStart = false
    }
    
    private func setDuration() {
        
    }
    
    private func setCurve() {
        
    }
    
}
