//
//  Interval.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit

public struct Interval: VDAnimationProtocol {
    public var modified: ModifiedAnimation {
        ModifiedAnimation(options: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    public let duration: AnimationDuration?
    
    public init<F: BinaryFloatingPoint>(_ duration: F) {
        self.duration = .absolute(Double(duration))
    }
    
    public init<F: BinaryFloatingPoint>(relative: F) {
        duration = .relative(Double(relative))
    }
    
    public init() {
        duration = nil
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
        let result = RemoteDelegate(completion)
        let seconds = options.duration?.absolute ?? duration?.absolute ?? 0
        DispatchTimer.execute(seconds: seconds) {
            guard !result.isStopped else { return }
            completion(true)
        }
        return result.delegate
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {}
    
}

enum DispatchTimer {
    
    static func execute(after time: DispatchTimeInterval, on queue: DispatchQueue = .main, _ handler: @escaping () -> Void) {
        var timer: DispatchSourceTimer? = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.schedule(deadline: .now() + time, repeating: .never)
        timer?.setEventHandler {
            handler()
            timer = nil
        }
        timer?.activate()
    }
    
    static func execute(seconds: TimeInterval, on queue: DispatchQueue = .main, _ handler: @escaping () -> Void) {
        execute(after: .nanoseconds(Int(seconds * 1_000_000_000)), on: queue, handler)
    }
    
}
