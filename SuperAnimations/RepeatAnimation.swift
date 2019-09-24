//
//  RepeatAnimation.swift
//  SuperAnimations
//
//  Created by Daniil on 21.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class RepeatAnimator<T: AnimatorProtocol>: AnimatorProtocol {
    public var parameters: AnimationParameters = .default
    private var current: Int = 0
    public var progress: Double {
        get { getProgress() }
        set { setProgress(newValue) }
    }
    public var isRunning: Bool { return animator.isRunning }
    public var state: UIViewAnimatingState { return animator.state }
    private var firstStart = true
    private(set) public var count: Int?
    private var animator: T
    
    init(on anim: T, _ cnt: Int?, parameters: AnimationParameters) {
        animator = anim//.onComplete {[weak self] _ in self?._start() }
        count = cnt
        self.parameters = parameters
        animator = anim
    }
    
    public func start() {
        guard !isRunning else { return }
        _start(nil)
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        _start(completion)
    }
    
    private func _start(_ completion: ((UIViewAnimatingPosition) -> ())?) {
        configureChildren()
        guard needRepeat() else {
            parameters.completion(.end)
            completion?(.end)
            return
        }
        if current > 0 {
            animator.progress = 0
        }
        current += 1
        animator.start {[weak self] _ in self?._start(completion) }
    }
    
    private func needRepeat() -> Bool {
        if let common = count {
            return current < common
        }
        return true
    }
    
    public func pause() {
        configureChildren()
        animator.pause()
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        animator.stop(at: position)
        switch position {
        case .start:    current = 0
        case .end:      current = count ?? 0
        default:        break
        }
    }
    
    public func copy(with parameters: AnimationParameters) -> RepeatAnimator<T> {
        return RepeatAnimator(on: animator, count, parameters: parameters)
    }
    
    private func getProgress() -> Double {
        configureChildren()
        guard let cnt = count, cnt != 1 else { return animator.progress }
        guard cnt > 0 else { return 0 }
        guard current < cnt else { return 1 }
        return (Double(current) + animator.progress) / Double(cnt)
    }
    
    private func setProgress(_ value: Double) {
        configureChildren()
        guard let cnt = count, cnt != 1 else { return animator.progress = value }
        guard cnt > 0 else { return animator.progress = 0 }
        let scaled = value * Double(cnt)
        current = Int(scaled)
        guard current < cnt else {
            animator.progress = 1
            return
        }
        animator.progress = scaled.truncatingRemainder(dividingBy: 1)
    }
    
    private func configureChildren() {
        guard firstStart else { return }
        setDuration()
        setCurve()
        firstStart = false
    }
    
    private func setDuration() {
        let cnt = Double(count ?? 1)
        var duration: Double?
        if let _duration = (parameters.realTiming.duration ?? parameters.settedTiming.duration)?.fixed {
            duration = cnt > 0 ? _duration / cnt : 0
        } else {
            parameters.realTiming.duration = .absolute(count == nil ? .infinity : animator.timing.duration * cnt)
        }
        animator.set(duration: duration, curve: nil)
    }
    
    private func setCurve() {
        
    }
    
}
