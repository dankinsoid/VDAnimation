//
//  Interval.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct Interval: AnimationProviderProtocol {
    
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    public let duration: AnimationDuration?
    
    public init(_ duration: Double) {
        self.duration = .absolute(duration)
    }
    
    public init(relative: Double) {
        duration = .relative(relative)
    }
    
    public init() {
        duration = nil
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        DispatchTimer.execute(seconds: options.duration?.absolute ?? duration?.absolute ?? 0) {
            completion(true)
        }
    }
    
    public func canSet(state: AnimationState, for options: AnimationOptions) -> Bool { true }
    public func set(state: AnimationState, for options: AnimationOptions) {}
    
}

enum DispatchTimer {
    
    static func execute(after time: DispatchTimeInterval, on queue: DispatchQueue = .main, _ handler: @escaping () -> ()) {
        var timer: DispatchSourceTimer? = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.schedule(deadline: .now() + time, repeating: .never)
        timer?.setEventHandler {
            handler()
            timer = nil
        }
        timer?.activate()
    }
    
    static func execute(seconds: TimeInterval, on queue: DispatchQueue = .main, _ handler: @escaping () -> ()) {
        execute(after: .nanoseconds(Int(seconds * 1_000_000_000)), on: queue, handler)
    }
    
}
