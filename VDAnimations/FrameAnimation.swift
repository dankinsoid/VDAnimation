//
//  FrameAnimation.swift
//  CA
//
//  Created by Daniil on 11.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct FrameAnimation: AnimationProviderProtocol {
    private let preferredFramesPerSecond: Int
    private let update: (Double) -> ()
    private let curve: ((Double) -> Double)?
    
    init(fps: Int, curve: ((Double) -> Double)?, _ update: @escaping (Double) -> ()) {
        self.preferredFramesPerSecond = fps
        self.update = update
        self.curve = curve
    }
    
    public init(fps: Int, _ update: @escaping (Double) -> ()) {
        self = FrameAnimation(fps: fps, curve: nil, update)
    }
    
    public init(_ update: @escaping (Double) -> ()) {
        self = FrameAnimation(fps: 0, curve: nil, update)
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        let duration = options.duration?.absolute ?? 0
        let isReversed = options.isReversed
        guard duration > 0 else {
            update(isReversed ? 0 : 1)
            completion(true)
            return
        }
        let owner = Owner<CATimer?>(nil)
        let timer = CATimer(preferredFPS: preferredFramesPerSecond) {
            let percent = $0 / duration
            guard percent < 1 else {
                self.update(isReversed ? 0 : 1)
                owner.object?.stop()
                owner.object = nil
                completion(true)
                return
            }
            let k = isReversed ? 1 - percent : percent
            self.update(self.curve?(k) ?? k)
        }
        owner.object = timer
        timer.start()
    }

    public func set(state: AnimationState, for options: AnimationOptions) {
        update(state.complete)
    }
    
}

fileprivate final class CATimer: NSObject {
    
    let preferredFramesPerSecond: Int
    let update: (TimeInterval) -> ()
    private var startedAt: CFTimeInterval?
    
    private var displayLink: CADisplayLink?
    
    init(preferredFPS: Int, _ update: @escaping (TimeInterval) -> ()) {
        self.preferredFramesPerSecond = preferredFPS
        self.update = update
    }
    
    func start() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(handler))
        displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
        startedAt = CACurrentMediaTime()
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stop() {
        displayLink?.isPaused = true
        displayLink?.invalidate()
        displayLink = nil
        startedAt = nil
    }
    
    @objc private func handler(displayLink: CADisplayLink) {
//        print(displayLink.targetTimestamp - CACurrentMediaTime())
        update(displayLink.timestamp - (startedAt ?? CACurrentMediaTime()))
    }
    
}

fileprivate final class Owner<T> {
    var object: T
    
    init(_ object: T) {
        self.object = object
    }
}
