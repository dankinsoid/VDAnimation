//
//  FrameAnimation.swift
//  CA
//
//  Created by Daniil on 11.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Renamed to 'TimerAnimation'")
public typealias ForEachFrame = TimerAnimation

public struct TimerAnimation: VDAnimationProtocol {
	public let fps: Int
	private let update: (CGFloat, FrameInfo) -> Void
	private let curve: ((CGFloat) -> CGFloat)?
	
	init(fps: Int, curve: ((CGFloat) -> CGFloat)?, _ update: @escaping (CGFloat, FrameInfo) -> Void) {
		self.fps = fps
		self.update = update
		self.curve = curve
	}
	
	public init(fps: Int = 0, _ update: @escaping (CGFloat) -> Void) {
		self = TimerAnimation(fps: fps, curve: nil, { p, _ in update(p) })
	}
	
	public init(fps: Int = 0, _ update: @escaping (CGFloat, FrameInfo) -> Void) {
		self = TimerAnimation(fps: fps, curve: nil, update)
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(fps: fps, curve: curve, update, options: options)
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { displayLink?.isPaused == false }
		var position: AnimationPosition {
			get { .progress(currentProgress(displayLink: displayLink)) }
			set {
				if displayLink?.isPaused != false {
					settedProgress = newValue.complete
					update(CGFloat(newValue.complete), displayLink.info(fps))
				} else {
					settedProgress = nil
				}
			}
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		private let fps: Int
		private let update: (CGFloat, FrameInfo) -> Void
		private let curve: ((CGFloat) -> CGFloat)?
		private var completions: [(Bool) -> Void] = []
		private var settedProgress: Double?
		
		private var startedAt: CFTimeInterval?
		private var pausedAt: CFTimeInterval?
		private var pausedTime: CFTimeInterval = 0
		private var displayLink: CADisplayLink?
		private var block: ((CGFloat) -> CGFloat)?
		private var wasCompleted = false
		private var wasPlayed = false
		
		init(fps: Int, curve: ((CGFloat) -> CGFloat)?, _ update: @escaping (CGFloat, FrameInfo) -> Void, options: AnimationOptions) {
			self.fps = fps
			self.update = update
			self.curve = curve
			self.options = options
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		func play(with options: AnimationOptions) {
			self.options = options.or(self.options)
			wasPlayed = true
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
				update(progress, displayLink.info(fps))
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
		}
		
		private func completion(_ completed: Bool) {
			guard wasPlayed, !wasCompleted else { return }
			wasCompleted = true
			completions.forEach {
				$0(completed)
			}
		}
		
		func start() {
			guard currentProgress(displayLink: displayLink) < 1 else {
				stop()
				update(options.isReversed == true ? 0 : 1, displayLink.info(fps))
				completion(true)
				return
			}
			wasPlayed = true
			wasCompleted = false
			block = transform()
			createAndStart()
		}
		
		func createAndStart() {
			if displayLink == nil {
				if let setted = settedProgress, let dur = options.duration?.absolute, dur > 0 {
					pausedTime = setted / dur
				} else {
					pausedTime = 0
				}
				pausedAt = nil
				displayLink = displayLink ?? CADisplayLink(target: self, selector: #selector(handler))
				displayLink?.preferredFramesPerSecond = fps
				startedAt = CACurrentMediaTime()
				displayLink?.add(to: .main, forMode: .default)
			} else if displayLink?.isPaused == true {
				if let setted = settedProgress, let dur = options.duration?.absolute, dur > 0 {
					pausedTime = setted / dur
				} else {
					pausedTime += pausedAt.map { CACurrentMediaTime() - $0 } ?? 0
				}
				pausedAt = nil
				displayLink?.isPaused = false
			}
			settedProgress = nil
		}
		
		@objc private func handler(displayLink: CADisplayLink) {
			let percent = CGFloat(currentProgress(displayLink: displayLink))
			guard percent < 1 else {
				self.update(options.isReversed == true ? 0 : 1, displayLink.info)
				stop()
				completion(true)
				return
			}
			let k = options.isReversed == true ? 1 - percent : percent
			self.update(block?(k) ?? k, displayLink.info)
		}
		
		private func currentProgress(displayLink: CADisplayLink?) -> Double {
			if let setted = settedProgress, displayLink?.isPaused != false {
				return setted
			}
			guard let displayLink = displayLink else { return 0 }
			let time = displayLink.timestamp - (startedAt ?? CACurrentMediaTime()) - pausedTime
			let duration = options.duration?.absolute ?? 0
			guard duration > 0 else { return 1 }
		  return time / duration
		}
		
		private func transform() -> ((CGFloat) -> CGFloat)? {
			guard let bezier = options.curve, bezier != .linear else { return curve }
			return {[curve] in
				bezier.y(at: curve?($0) ?? $0)
			}
		}
	}
	
	public struct FrameInfo {
		///The time value associated with the next frame that was displayed.
		///You can use the target timestamp to cancel or pause long running processes
		///that may overrun the available time between frames in order to maintain a consistent frame rate.
		public var targetTimestamp: CFTimeInterval { displayLink?.targetTimestamp ?? (CACurrentMediaTime() + 1 / fps) }
		///The time value associated with the last frame that was displayed.
		public var timestamp: CFTimeInterval { displayLink?.timestamp ?? CACurrentMediaTime() }
		///The time interval between screen refresh updates.
		public var duration: CFTimeInterval { displayLink?.duration ?? (1 / fps) }
		public var isOverrun: Bool {
			displayLink.map { CACurrentMediaTime() >= $0.targetTimestamp } ?? false
		}
		public var actualFps: CFTimeInterval {
			displayLink.map { 1 / ($0.targetTimestamp - $0.timestamp) } ?? fps
		}
		
		var displayLink: CADisplayLink?
		let fps: CFTimeInterval
	}
}

extension CADisplayLink {
	var info: TimerAnimation.FrameInfo { .init(displayLink: self, fps: CFTimeInterval(preferredFramesPerSecond)) }
}

extension Optional where Wrapped == CADisplayLink {
	func info(_ fps: Int) -> TimerAnimation.FrameInfo {
		.init(displayLink: self, fps: CFTimeInterval(fps))
	}
}
