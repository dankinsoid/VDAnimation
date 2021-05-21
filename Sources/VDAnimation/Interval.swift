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
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(options: options.or(AnimationOptions(duration: duration)))
	}

	final class Delegate: AnimationDelegateProtocol {
		var isInstant: Bool { false }
		var isRunning: Bool {
			startedAt != nil && stoppedAt == nil && pausedAt == nil
		}
		var position: AnimationPosition {
			get {
				guard duration > 0 else { return .end }
				return settedPosition ?? completed.map { .progress(startedFrom + (options.isReversed == true ? -$0 : $0)) } ?? .start
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
		private var current: UUID?
		private var startedAt: CFTimeInterval?
		private var startedFrom = 0.0
		private var pausedAt: CFTimeInterval?
		private var stoppedAt: CFTimeInterval?
		var duration: TimeInterval = 0
		
		private var settedPosition: AnimationPosition?
		private var completed: Double? {
			guard duration > 0 else { return 1 }
			return startedAt.flatMap { started in
				((pausedAt ?? stoppedAt ?? CACurrentMediaTime()) - started) / duration
			}
		}
		
		init(options: AnimationOptions) {
			self.options = options
		}
		
		func play(with options: AnimationOptions) {
			self.options = options.or(self.options)
			guard !isRunning, stoppedAt == nil else { return }
			duration = self.options.duration?.absolute ?? 0
			let seconds = (settedPosition?.complete ?? completed).map { duration * (options.isReversed == true ? $0 : 1 - $0) } ?? duration
			startedFrom = settedPosition?.complete ?? completed ?? 0
			settedPosition = nil
			pausedAt = nil
			guard seconds > 0 else {
				startedAt = startedAt ?? CACurrentMediaTime()
				stop(at: .end)
				return
			}
			let id = UUID()
			current = id
			startedAt = startedAt ?? CACurrentMediaTime()
			DispatchTimer.execute(seconds: seconds) {
				guard self.current == id else { return }
				self.stop(at: .end)
			}
		}
		
		func pause() {
			if startedAt != nil {
				pausedAt = CACurrentMediaTime()
			}
			current = nil
		}
		
		func stop(at position: AnimationPosition?) {
			current = nil
			settedPosition = nil
			if options.complete != false {
				stoppedAt = CACurrentMediaTime()
				pausedAt = nil
			} else {
				stoppedAt = nil
				pausedAt = CACurrentMediaTime()
			}
			complete(complete: position == .end)
		}
		
		private func complete(complete: Bool) {
			completions.forEach {
				$0(complete)
			}
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
	}
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
