//
//  SequentialDelegate.swift
//  VDTransition
//
//  Created by Данил Войдилов on 22.03.2021.
//

import Foundation
import VDKit

internal final class SequentialDelegate: AnimationDelegateProtocol {
	
	// MARK: protocol properties
	internal var isRunning: Bool { current?.isRunning ?? false }
	internal let animations: [AnimationDelegateProtocol]
	internal var options: AnimationOptions
	var isInstant: Bool { !animations.contains(where: { !$0.isInstant }) }
	internal var position: AnimationPosition {
		get { getPosition() }
		set { set(position: newValue) }
	}
	
	// MARK: private properties
	private var completions: [(Bool) -> Void] = []
	private var allOptions: [AnimationOptions] = []
	private let initOptions: [AnimationOptions]
	private var progresses: [ClosedRange<Double>] = []
	private var wasPlaying = false
	private var fullDuration: AnimationDuration?
	private var wasStopped = false
	private var stopped = 0
	private var currentStep: Int
	private var current: AnimationDelegateProtocol? {
		animations[safe: currentStep % animations.count]
	}
	
	// MARK: init
	
	internal init(animations: [AnimationDelegateProtocol], options: AnimationOptions) {
		self.animations = animations
		self.fullDuration = SequentialDelegate.fullDuration(for: animations)
		self.options = options.or(AnimationOptions(duration: fullDuration))
		initOptions = animations.map { $0.options }
		currentStep = 0
		prepare()
	}
	
	// MARK: protocol methods
	
	internal func play(with options: AnimationOptions) {
		if options != .empty {
			self.options = options.or(self.options)
			updateOptions()
		}
		guard !animations.isEmpty else {
			completions.forEach {
				$0(true)
			}
			return
		}
		wasPlaying = true
		wasStopped = false
		current?.play(with: allOptions[currentStep])
	}
	
	internal func pause() {
		current?.pause()
	}
	
	internal func stop(at position: AnimationPosition?) {
		wasStopped = true
		set(progress: position?.complete, complete: options.complete ?? true)
	}
	
	internal func add(completion: @escaping (Bool) -> Void) {
		completions.append(completion)
	}
	
	// MARK: private methods
	
	private func prepare() {
		updateOptions()
		animations.enumerated().forEach { args in
			let (index, animation) = args
			animation.add {[weak self] completed in
				self?.completed(completed: completed, index: index)
			}
		}
	}
	
	private func completed(completed: Bool, index: Int) {
		guard !wasStopped else {
			stopped += 1
			if stopped == animations.count {
				stopped = 0
				completions.forEach { $0(completed) }
			}
			return
		}
		let newStep = index + (options.isReversed == true ? -1 : 1)
		let finished = newStep < 0 || newStep >= animations.count
		currentStep = max(0, min(animations.count - 1, newStep))
		if finished || !completed {
			if options.complete != false {
				wasStopped = true
				animations.forEach {
					$0.stop(at: .current)
				}
			} else {
				completions.forEach { $0(completed) }
			}
		} else if !animations.isEmpty {
			animations[newStep].position = options.isReversed == true ? .end : .start
			animations[newStep].play(with: allOptions[newStep])
		}
	}
	
	// MARK: options methods
	
	private func updateOptions() {
		progresses = getProgresses()
		allOptions = setDuration()
	}
	
	private func setDuration() -> [AnimationOptions] {
		let full = options.duration?.absolute ?? fullDuration?.absolute ?? 0
		guard full > 0 else {
			return [AnimationOptions](repeating: options.set(.duration(.absolute(0))), count: animations.count)
		}
		var ks: [Double?] = []
		var childrenRelativeTime = 0.0
		for anim in animations {
			var k: Double?
			if let absolute = anim.options.duration?.absolute {
				k = absolute / full
			} else if let relative = anim.options.duration?.relative {
				k = relative
			}
			childrenRelativeTime += k ?? 0
			ks.append(k)
		}
		let cnt = ks.filter({ $0 == nil }).count
		let relativeK = cnt > 0 ? max(1, childrenRelativeTime) : childrenRelativeTime
		var add = (1 - min(1, childrenRelativeTime))
		if cnt > 0 {
			add /= Double(cnt)
		}
		var result: [AnimationOptions]
		if relativeK == 0 {
			result = [AnimationOptions](
				repeating: options.set([.duration(.absolute(full / Double(animations.count))), .complete(false)]),
				count: animations.count
			)
		} else {
			result = ks.map({ options.set([.duration(.absolute(full * ($0 ?? add) / relativeK)), .complete(false)]) })
		}
		setCurve(&result, duration: full, options: options)
		return result
	}
	
	private func setCurve(_ array: inout [AnimationOptions], duration: Double, options: AnimationOptions) {
		guard let fullCurve = options.curve, fullCurve != .linear else { return }
		for i in 0..<animations.count {
			var (curve1, newDuration) = fullCurve.split(range: progresses[i])
			if let curve2 = animations[i].options.curve {
				curve1 = BezierCurve.between(curve1, curve2)
			}
			array[i].duration = .absolute(duration * newDuration)
			array[i].curve = curve1
		}
	}
	
	// MARK: position methods
	
	private func getPosition() -> AnimationPosition {
		guard !progresses.isEmpty else { return .end }
		if currentStep == 0, current?.position == .start {
			return .start
		}
		if currentStep == animations.count - 1, current?.position == .end {
			return .end
		}
		return .progress((progresses[currentStep].upperBound - progresses[currentStep].lowerBound) * animations[currentStep].position.complete + progresses[currentStep].lowerBound)
	}
	
	private func set(position: AnimationPosition) {
		guard !animations.isEmpty else { return }
		switch position {
		case .start:
			animations.reversed().forEach { $0.position = .start }
			currentStep = 0
			wasPlaying = true
		case .end:
			animations.forEach { $0.position = .end }
			currentStep = max(0, animations.count - 1)
			wasPlaying = true
		case .progress(let k):
			set(progress: k, complete: false)
		}
	}
	
	private func set(progress k: Double?, complete: Bool) {
		let i = k.map { k in progresses.firstIndex(where: { k >= $0.lowerBound && k <= $0.upperBound }) ?? 0 } ?? currentStep
		if k != nil {
			let finished = currentStep
			let toFinish = i > finished || !wasPlaying ? animations.dropFirst(finished).prefix(i - finished) : []
			let p = wasPlaying ? currentStep : animations.count - 1
			let started = animations.count - p - 1
			let toStart = i < finished || !wasPlaying ? animations.dropLast(started).suffix((wasPlaying ? currentStep : p) - i) : []
			toFinish.forEach {
				$0.set(position: .end, stop: complete)
			}
			toStart.reversed().forEach {
				$0.set(position: .start, stop: complete)
			}
		}
		if progresses[i].upperBound == progresses[i].lowerBound {
			animations[i].set(position: .end, stop: complete)
		} else if let k = k {
			let progress = AnimationPosition.progress((k - progresses[i].lowerBound) / (progresses[i].upperBound - progresses[i].lowerBound))
			animations[i].set(position: progress, stop: complete)
		} else if complete {
			animations[i].stop(at: .current)
		}
		wasPlaying = true
		currentStep = i
	}
	
	private func getProgresses() -> [ClosedRange<Double>] {
		guard !animations.isEmpty else { return [] }
		let array = initOptions
		let duration = options.duration?.absolute ?? fullDuration?.absolute ?? 0
		guard duration > 0 else {
			return getProgresses(array)
		}
		var progresses: [ClosedRange<Double>] = []
		var dur = 0.0
		var start = 0.0
		let cnt = Double(array.filter({ $0.duration == nil }).count)
		let full: Double = array.map { it -> Double in
			it.duration?.relative ?? (it.duration?.absolute ?? 0) / duration
		}.reduce(0, +)
		let remains = max(0, 1 - full) / max(1, cnt)
		for anim in array {
			if let rel = anim.duration?.relative {
				dur += min(1, max(0, rel))
			} else if let abs = anim.duration?.absolute {
				dur += abs / duration
			} else {
				dur += remains
			}
			let end = min(1, dur)
			progresses.append(start...end)
			start = end
		}
		progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
		return progresses
	}
	
	private func getProgresses(_ array: [AnimationOptions]) -> [ClosedRange<Double>] {
		let cnt = Double(array.filter({ $0.duration?.relative == nil }).count)
		let full = min(1, array.reduce(0, { $0 + ($1.duration?.relative ?? 0) }))
		let each = (1 - full) / cnt
		var progresses: [ClosedRange<Double>] = []
		var dur = 0.0
		var start = 0.0
		for anim in array {
			if let rel = anim.duration?.relative {
				dur += min(1, max(0, rel))
			} else {
				dur += each
			}
			let end = min(1, dur)
			progresses.append(start...end)
			start = end
		}
		progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
		return progresses
	}
	
	// MARK: static methods
	
	private static func fullDuration(for array: [AnimationDelegateProtocol]) -> AnimationDuration? {
		guard array.contains(where: {
			$0.options.duration?.absolute != nil && !$0.isInstant
		}) else { return nil }
		let dur = array.reduce(0, { $0 + ($1.options.duration?.absolute ?? 0) })
		var rel = min(1, array.reduce(0, { $0 + ($1.options.duration?.relative ?? 0) }))
		if rel == 0 {
			rel = Double(array.filter({ $0.options.duration == nil }).count) / Double(array.count)
		}
		rel = rel == 1 ? 0 : rel
		let full = dur / (1 - rel)
		return .absolute(full)
	}
}
