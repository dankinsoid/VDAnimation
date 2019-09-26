//
//  Interval.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Interval: ExpressibleByFloatLiteral, AnimatorProtocol {
    public var timing: Animate.Timing { .setted(parameters.settedTiming) }
    public var parameters: AnimationParameters = .default
    public var state: UIViewAnimatingState = .inactive
    private(set) public var isRunning: Bool = false
    public var progress: Double {
        get { _progress }
        set { setProgress(newValue) }
    }
    private var _progress: Double = 0
    private var currentObservers: [(UIViewAnimatingPosition) -> ()] = []
    private var startTime: CFTimeInterval?
    private var executed: CFTimeInterval?
    private var cancelled: Set<UUID> = []
    private var current: UUID?
    private weak var timer: Timer?
    
    public init() {}
    
    public init(_ value: Double) {
        self.parameters.settedTiming.duration = .absolute(value)
    }
    
    public init(relative value: Double) {
        self.parameters.settedTiming.duration = .relative(value)
    }
    
    public init(floatLiteral value: Double) {
        self.parameters.settedTiming.duration = .absolute(value)
    }
    
    public func copy(with parameters: AnimationParameters) -> Interval {
        let copy = Interval()
        copy.parameters.settedTiming = parameters.settedTiming
        return copy
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        self.currentObservers.append(completion)
        guard !isRunning else {
            return
        }
        let id = UUID()
        current = id
        let duration = max(0, timing.duration - (executed ?? 0))
        startTime = CACurrentMediaTime()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            guard !self.cancelled.contains(id) else {
                self.cancelled.remove(id)
                return
            }
            self._stop(position: .end)
        }
        state = .active
        isRunning = true
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        _stop(position: position)
    }
    
    private func _stop(position: UIViewAnimatingPosition) {
        pause(at: position, progress: nil)
        let observers = currentObservers + [parameters.completion]
        currentObservers = []
        observers.forEach { $0(position) }
    }
    
    public func pause() {
        pause(at: .current, progress: nil)
    }
    
    private func pause(at position: UIViewAnimatingPosition, progress percent: Double?) {
        state = .stopped
        isRunning = false
        if let id = current {
            cancelled.insert(id)
            current = nil
        }
        timer?.invalidate()
        switch position {
        case .current:
            var _executed: CFTimeInterval = executed ?? 0
            if let per = percent {
                _executed = timing.duration * per
            } else if let start = startTime {
                _executed += CACurrentMediaTime() - start
            }
            _progress = timing.duration > 0 ? _executed / timing.duration : 1
            executed = _executed
        case .end:
            _progress = 1
            executed = nil
        case .start:
            _progress = 0
            executed = nil
        @unknown default:
            _progress = 1
            executed = nil
        }
        startTime = nil
    }
    
    private func setProgress(_ value: Double) {
        pause(at: .current, progress: value)
    }
    
}
