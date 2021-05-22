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
		var isInstant: Bool { false }
		var isRunning: Bool {
			displayLink?.isPaused == false
		}
		var position: AnimationPosition {
			get {
				guard duration > 0 else { return settedPosition ?? .start }
				return settedPosition ?? completed.map {
					.progress(min(1, max(0, startedFrom + (options.isReversed == true ? -$0 : $0))))
				} ?? .start
			}
			set {
				let wasRunning = isRunning
				if wasRunning {
					pause()
				}
				settedPosition = newValue
				if wasRunning {
					play(with: .empty)
				}
			}
		}
		var options: AnimationOptions
		private var completions: [(Bool) -> Void] = []
		private var startedAt: CFTimeInterval?
		private var startedFrom = 0.0
		private var pausedAt: CFTimeInterval?
		private var stoppedAt: CFTimeInterval?
		private var displayLink: CADisplayLink?
		private var block: ((CGFloat) -> CGFloat)?
		private var curve: ((CGFloat) -> CGFloat)?
		private let update: (CGFloat, FrameInfo) -> Void
		private let fps: Int
		private var duration: Double { options.duration?.absolute ?? 0 }
		
		private var settedPosition: AnimationPosition?
		private var completed: Double? {
			guard duration > 0 else { return startedAt == nil ? nil : 1 }
			return startedAt.flatMap { started in
				min(1, max(0, ((pausedAt ?? stoppedAt ?? CACurrentMediaTime()) - started) / duration))
			}
		}
		
		init(fps: Int, curve: ((CGFloat) -> CGFloat)?, _ update: @escaping (CGFloat, FrameInfo) -> Void, options: AnimationOptions) {
			self.fps = fps
			self.update = update
			self.curve = curve
			self.options = options
		}
		
		func play(with options: AnimationOptions) {
			guard !isRunning, stoppedAt == nil else { return }
			let currentProgress = progress
			self.options = options.or(self.options)
			let seconds = duration * (self.options.isReversed ?? false ? currentProgress : 1 - currentProgress)
			startedFrom = settedPosition?.complete ?? completed ?? 0
			settedPosition = nil
			pausedAt = nil
			guard seconds > 0 else {
				startedAt = startedAt ?? CACurrentMediaTime()
				stop(at: .end, complete: self.options.complete != false)
				return
			}
			startedAt = startedAt ?? CACurrentMediaTime()
			
			block = transform()
			if displayLink == nil {
				displayLink = CADisplayLink(target: self, selector: #selector(handler))
				displayLink?.preferredFramesPerSecond = fps
				displayLink?.add(to: .main, forMode: .default)
			} else {
				displayLink?.isPaused = false
			}
		}
		
		@objc private func handler(displayLink: CADisplayLink) {
			let k = CGFloat(progress)
			update(block?(k) ?? k, displayLink.info)
			if k == (options.isReversed == true ? 0 : 1) {
				stop(at: nil, complete: options.complete != false)
			}
		}
		
		func pause() {
			displayLink?.isPaused = true
			if startedAt != nil {
				pausedAt = CACurrentMediaTime()
			}
		}
		
		func stop(at position: AnimationPosition?) {
			stop(at: position, complete: true)
		}
		
		private func stop(at position: AnimationPosition?, complete: Bool) {
			displayLink?.isPaused = true
			displayLink?.invalidate()
			displayLink = nil
			settedPosition = nil
			if complete {
				stoppedAt = CACurrentMediaTime()
				pausedAt = nil
			} else {
				stoppedAt = nil
				pausedAt = CACurrentMediaTime()
			}
			self.complete(complete: position == .end)
		}
		
		private func complete(complete: Bool) {
			completions.forEach {
				$0(complete)
			}
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
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
