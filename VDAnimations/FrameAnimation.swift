//
//  FrameAnimation.swift
//  CA
//
//  Created by Daniil on 11.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct ForEachFrame: VDAnimationProtocol {
    private let preferredFramesPerSecond: Int
    private let update: (Double) -> ()
    private let curve: ((Double) -> Double)?
    
    init(fps: Int, curve: ((Double) -> Double)?, _ update: @escaping (Double) -> ()) {
        self.preferredFramesPerSecond = fps
        self.update = update
        self.curve = curve
    }
    
    public init(fps: Int, _ update: @escaping (Double) -> ()) {
        self = ForEachFrame(fps: fps, curve: nil, update)
    }
    
    public init(_ update: @escaping (Double) -> ()) {
        self = ForEachFrame(fps: 0, curve: nil, update)
    }
        
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationPosition {
        let duration = options.duration?.absolute ?? 0
        let isReversed = options.isReversed
        guard duration > 0 else {
            update(isReversed ? 0 : 1)
            completion(true)
            return
        }
        let owner = Owner<CATimer?>(nil)
        let block = transform(options: options)
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
            self.update(block?(k) ?? k)
        }
        owner.object = timer
        timer.start()
    }

    public func set(position: AnimationPosition, for options: AnimationOptions) {
        update(position.complete)
    }
    
    private func transform(options: AnimationOptions) -> ((Double) -> Double)? {
        guard let bezier = options.curve, bezier != .linear else { return curve }
        return {[curve] in
            Double(bezier.progress(at: CGFloat(curve?($0) ?? $0)))
        }
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

public struct FrameInfo {
    public let progress: Double
    public let remains: CFTimeInterval
}

fileprivate final class Owner<T> {
    var object: T
    
    init(_ object: T) {
        self.object = object
    }
}
