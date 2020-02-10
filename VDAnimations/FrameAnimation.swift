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
    
    public init(fps: Int, _ update: @escaping (Double) -> ()) {
        self.preferredFramesPerSecond = fps
        self.update = update
    }
    
    public init(_ update: @escaping (Double) -> ()) {
        self = FrameAnimation(fps: 0, update)
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        let duration = options.duration?.absolute ?? 0
        guard duration > 0 else {
            update(1)
            completion(true)
            return
        }
        let owner = Owner<CATimer?>(nil)
        let timer = CATimer(preferredFPS: preferredFramesPerSecond) {
            let percent = $0 / duration
            guard percent < 1 else {
                self.update(1)
                owner.object?.stop()
                owner.object = nil
                completion(true)
                return
            }
            self.update(percent)
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
    var onDeinit: () -> () = {}
    private var startedAt: CFTimeInterval?
    
    private var displayLink: CADisplayLink?
    
    init(preferredFPS: Int, _ update: @escaping (TimeInterval) -> ()) {
        self.preferredFramesPerSecond = preferredFPS
        self.update = update
    }
    
    deinit {
        stop()
        onDeinit()
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
        update(displayLink.timestamp - (startedAt ?? CACurrentMediaTime()))
    }
    
}

fileprivate final class Owner<T> {
    var object: T
    
    init(_ object: T) {
        self.object = object
    }
}
