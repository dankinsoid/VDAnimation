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
	private let update: (CGFloat) -> Void
	private let curve: ((CGFloat) -> CGFloat)?
	
	init(fps: Int, curve: ((CGFloat) -> CGFloat)?, _ update: @escaping (CGFloat) -> Void) {
		self.preferredFramesPerSecond = fps
		self.update = update
		self.curve = curve
	}
	
	public init(fps: Int = 0, _ update: @escaping (CGFloat) -> Void) {
		self = ForEachFrame(fps: fps, curve: nil, update)
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(fps: preferredFramesPerSecond, curve: curve, update, options: options)
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { displayLink?.isPaused == false }
		var position: AnimationPosition {
			get { .progress(currentProgress(displayLink: displayLink)) }
			set { update(CGFloat(newValue.complete)) }
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		private let preferredFramesPerSecond: Int
		private let update: (CGFloat) -> Void
		private let curve: ((CGFloat) -> CGFloat)?
		private var completions: [(Bool) -> Void] = []
		
		private var startedAt: CFTimeInterval?
		private var pausedAt: CFTimeInterval?
		private var pausedTime: CFTimeInterval = 0
		private var displayLink: CADisplayLink?
		private var block: ((CGFloat) -> CGFloat)?
		
		init(fps: Int, curve: ((CGFloat) -> CGFloat)?, _ update: @escaping (CGFloat) -> Void, options: AnimationOptions) {
			self.preferredFramesPerSecond = fps
			self.update = update
			self.curve = curve
			self.options = options
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		func play(with options: AnimationOptions) {
			self.options = options.or(self.options)
			start()
		}
		
		func pause() {
			guard displayLink?.isPaused == false else { return }
			displayLink?.isPaused = true
			pausedAt = CACurrentMediaTime()
		}
		
		func stop(at position: AnimationPosition?) {
			stop()
			if let progress = (position?.complete).map({ CGFloat($0) }) {
				update(progress)
				completion(progress == 1)
			} else {
				completion(false)
			}
		}
		
		func stop() {
			displayLink?.isPaused = true
			displayLink?.invalidate()
			displayLink = nil
			startedAt = nil
			pausedAt = nil
			completion(true)
		}
		
		private func completion(_ completed: Bool) {
			completions.forEach {
				$0(completed)
			}
		}
		
		func start() {
			let duration = options.duration?.absolute ?? 0
			guard duration > 0 else {
				stop()
				update(options.isReversed == true ? 0 : 1)
				completion(true)
				return
			}
			block = transform()
			createAndStart()
		}
		
		func createAndStart() {
			if displayLink == nil {
				pausedTime = 0
				pausedAt = nil
				displayLink = displayLink ?? CADisplayLink(target: self, selector: #selector(handler))
				displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
				startedAt = CACurrentMediaTime()
				displayLink?.add(to: .main, forMode: .default)
			} else if displayLink?.isPaused == true {
				pausedTime += pausedAt.map { CACurrentMediaTime() - $0 } ?? 0
				pausedAt = nil
				displayLink?.isPaused = false
			}
		}
		
		@objc private func handler(displayLink: CADisplayLink) {
			let percent = CGFloat(currentProgress(displayLink: displayLink))
			guard percent < 1 else {
				self.update(options.isReversed == true ? 0 : 1)
				stop()
				return
			}
			let k = options.isReversed == true ? 1 - percent : percent
			self.update(block?(k) ?? k)
		}
		
		private func currentProgress(displayLink: CADisplayLink?) -> Double {
			guard let displayLink = displayLink else { return 0 }
			let time = displayLink.timestamp - (startedAt ?? CACurrentMediaTime()) - pausedTime
			let duration = options.duration?.absolute ?? 0
		  return time / duration
		}
		
		private func transform() -> ((CGFloat) -> CGFloat)? {
			guard let bezier = options.curve, bezier != .linear else { return curve }
			return {[curve] in
				bezier.y(at: curve?($0) ?? $0)
			}
		}
	}
}

public struct FrameInfo {
	public let progress: Double
	public let remains: CFTimeInterval
}
