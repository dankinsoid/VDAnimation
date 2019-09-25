//
//  Interval.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Interval: ExpressibleByFloatLiteral, AnimatorProtocol {
    public var parameters: AnimationParameters = .default
    public var state: UIViewAnimatingState = .inactive
    private(set) public var isRunning: Bool = false
    public var progress: Double = 0
    
    public init() {}
    
    public init(_ value: Double) {
        self.parameters.userTiming.duration = .absolute(value)
    }
    
    public init(relative value: Double) {
        self.parameters.userTiming.duration = .relative(value)
    }
    
    public init(floatLiteral value: Double) {
        self.parameters.userTiming.duration = .absolute(value)
    }
    
    public func copy(with parameters: AnimationParameters) -> Interval {
        let copy = Interval()
        copy.parameters.userTiming = parameters.userTiming
        return copy
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        state = .active
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.duration) {
            guard self.isRunning else { return }
            completion(.end)
        }
        isRunning = true
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        state = .stopped
        if isRunning {
            
        }
        isRunning = false
    }
    
    public func pause() {
        isRunning = false
    }
    
}
