//
//  AnimateProperty.swift
//  CA
//
//  Created by Daniil on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

struct RepeatAnimation<A: VDAnimationProtocol>: VDAnimationProtocol {
	private let count: Int?
	private let animation: A
	
	init(_ count: Int?, for anim: A) {
		self.count = count
		animation = anim
	}
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(inner: animation.delegate(with: options), count: count, options: options)
	}
	
	final class Delegate: AnimationDelegateProtocol {
		let inner: AnimationDelegateProtocol
		var position: AnimationPosition {
			get { getPosition() }
			set {
				set(position: newValue, needStop: false)
			}
		}
		var options: AnimationOptions
		var isRunning: Bool { inner.isRunning }
		var isInstant: Bool { inner.isInstant }
		private var completions: [(Bool) -> Void] = []
		private let count: Int?
		private var current = 0
		private var hasStopped = false
		
		init(inner: AnimationDelegateProtocol, count: Int?, options: AnimationOptions) {
			self.inner = inner
			self.count = count
			let duration = Delegate.duration(for: count, from: options.duration)
			self.options = options.or(.duration(duration))
			prepare()
		}
		
		private func prepare() {
			inner.add {[weak self] in
				self?.completeOne($0)
			}
		}
		
		func play(with options: AnimationOptions) {
			self.options = options.or(self.options)
			guard !isRunning else { return }
			completeOne(true)
		}
		
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
			hasStopped = true
			guard let position = position else {
				inner.stop(at: .current)
				return
			}
			set(position: position, needStop: true)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		private func complete(_ complete: Bool) {
			completions.forEach {
				$0(complete)
			}
		}
		
		private func completeOne(_ completed: Bool) {
			if current == count || hasStopped {
				completions.forEach {
					$0(completed && (current == count || count == nil))
				}
			} else {
				if current > 0 {
					inner.position = options.isReversed == true ? .end : .start
				}
				let option = getOptions()
				current = current &+ 1
				inner.play(with: option)
			}
		}
		
		func set(position: AnimationPosition, needStop stop: Bool) {
			let position = options.isReversed == true ? position.reversed : position
			switch position {
			case .start, .end:
				inner.set(position: position, stop: stop)
			case .progress(let k):
				if count != nil {
					inner.set(position: .progress(getProgress(for: k)), stop: stop)
				} else {
					inner.set(position: position, stop: stop)
				}
			}
		}
		
		func getPosition() -> AnimationPosition {
			guard let cnt = count else { return inner.position }
			guard cnt > 0 else { return .end }
			return .progress(inner.position.complete / Double(cnt))
		}
		
		private func getProgress(for progress: Double) -> Double {
			guard let cnt = count, cnt > 0, progress != 1 else { return progress }
			let k = (progress * Double(cnt))
			return k.truncatingRemainder(dividingBy: 1)
		}
		
		private static func duration(for count: Int?, from dur: AnimationDuration?) -> AnimationDuration? {
			guard let cnt = count, let duration = dur, cnt > 0 else { return nil }
			switch duration {
			case .absolute(let time):   return .absolute(time * Double(cnt))
			case .relative(let time):   return .relative(time)
			}
		}
		
		private func getOptions() -> AnimationOptions {
			let i = options.isReversed == true ? (count ?? (current + 1)) - current - 1 : current
			let full = options.duration?.absolute ?? (inner.options.duration?.absolute ?? 0) * Double(count ?? 1)
			var result = options
			result.complete = options.complete != false && current == (count ?? .max) - 1
			guard let fullCurve = options.curve, fullCurve != .linear else {
				result.duration = .absolute(full / Double(count ?? 1))
				return result
			}
			let progresses = getProgress(i: i)
			let (curve1, newDuration) = fullCurve.split(range: progresses)
			result.duration = .absolute(full * newDuration)
			result.curve = curve1
			return result
		}
		
		private func getProgress(i: Int) -> ClosedRange<Double> {
			guard let cnt = count, cnt > 1 else { return 0...1 }
			let lenght = 1 / Double(cnt)
			var progress = (lenght * Double(i)...(lenght * Double(i) + lenght))
			if i == cnt - 1 {
				progress = min(1, progress.lowerBound)...1
			}
			return progress
		}
	}
}
