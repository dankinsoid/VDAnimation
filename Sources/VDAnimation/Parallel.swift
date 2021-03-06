//
//  Parallel.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public struct Parallel: VDAnimationProtocol {
	private let animations: [VDAnimationProtocol]
	public var modified: ModifiedAnimation {
		ModifiedAnimation(options: AnimationOptions.empty.chain.duration[maxDuration].apply(), animation: self)
	}
	private let maxDuration: AnimationDuration?
	private let interactor: Interactor
	
	public init(_ animations: [VDAnimationProtocol]) {
		self.animations = animations
		self.maxDuration = Parallel.maxDuration(for: animations)
		self.interactor = Interactor()
	}
	
	public init(_ animations: VDAnimationProtocol...) {
		self = .init(animations)
	}
	
	public init(@AnimationsBuilder _ animations: () -> [VDAnimationProtocol]) {
		self = .init(animations())
	}
	
	@discardableResult
	public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
		interactor.prevProgress = 0
		guard !animations.isEmpty else {
			completion(true)
			return .end
		}
		guard animations.count > 1 else {
			return animations[0].start(with: options, completion)
		}
		let array = getOptions(for: options)
		let full = options.duration?.absolute ?? maxDuration?.absolute ?? 0
		let delegates = Delegates()
		delegates.list.reserveCapacity(animations.count)
		let parallelCompletion = ParallelCompletion(animations.enumerated().map { arg in
			{ compl in
				if options.isReversed {
					let delay = full - (array[arg.offset].duration?.absolute ?? 0)
					let remote = RemoteDelegate()
					delegates.list.append(remote.delegate)
					DispatchTimer.execute(seconds: delay) {
						guard !remote.isStopped else { return compl(false) }
						delegates.list.append(arg.element.start(with: array[arg.offset], compl))
					}
				} else {
					delegates.list.append(arg.element.start(with: array[arg.offset], compl))
				}
			}
		})
		parallelCompletion.start {[interactor] in
			interactor.prevProgress = 1
			completion($0)
		}
		return delegate(for: delegates)
	}
	
	private func delegate(for array: Delegates) -> AnimationDelegate {
		AnimationDelegate {
			array.list.forEach { $0.stop(.start) }
			self.set(position: $0, for: .empty, execute: true)
			return $0
		}
	}
	
	public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
		let position = options.isReversed == true ? position.reversed : position
		switch position {
		case .start:
			animations.forEach { $0.set(position: position, for: .empty, execute: execute) }
			interactor.prevProgress = 0
		case .end:
			animations.forEach { $0.set(position: position, for: .empty, execute: execute) }
			interactor.prevProgress = 1
		case .progress(let k):
			guard !animations.isEmpty else { return }
			let array = getProgresses(animations.map({ $0.options }), duration: maxDuration?.absolute ?? 1, options: .empty)
			for i in 0..<array.count {
				if array[i].upperBound <= k || array[i].upperBound == 0 {
					guard array[i].upperBound > interactor.prevProgress else { continue }
					animations[i].set(position: .end, for: .empty, execute: execute)
				} else if array[i].lowerBound >= k {
					guard array[i].lowerBound < interactor.prevProgress else { continue }
					animations[i].set(position: .start, for: .empty, execute: false)
				} else {
					animations[i].set(position: .progress(k / array[i].upperBound), for: .empty, execute: execute)
				}
			}
			interactor.prevProgress = k
		case .current:
			animations.forEach { $0.set(position: position, for: .empty, execute: execute) }
		}
	}
	
	private func getOptions(for options: AnimationOptions) -> [AnimationOptions] {
		guard !animations.isEmpty else { return [] }
		let dur = options.duration?.absolute ?? maxDuration?.absolute ?? 0
		return setDuration(duration: dur, options: options)
	}
	
	private func setDuration(duration full: TimeInterval, options: AnimationOptions) -> [AnimationOptions] {
		guard !animations.isEmpty else { return [] }
		let maxDuration = self.maxDuration?.absolute ?? 0
		let k = maxDuration == 0 ? 1 : full / maxDuration
		let childrenDurations: [Double] = animations.map {
			guard let setted = $0.options.duration else {
				return full
			}
			switch setted {
			case .absolute(let time):   return time * k
			case .relative(let r):      return full * min(1, r)
			}
		}
		var result = childrenDurations.map({ options.chain.duration[.absolute($0)].apply() })
		setCurve(&result, duration: full, options: options)
		return result
	}
	
	private static func maxDuration(for array: [VDAnimationProtocol]) -> AnimationDuration? {
		guard array.contains(where: {
			$0.options.duration?.absolute != nil && !$0.options.isInstant
		}) else { return nil }
		let maxDuration = array.reduce(0, { max($0, $1.options.duration?.absolute ?? 0) })
		return .absolute(maxDuration)
	}
	
	private func setCurve(_ array: inout [AnimationOptions], duration: Double, options: AnimationOptions) {
		guard let fullCurve = options.curve, fullCurve != .linear else {
			return
		}
		let progresses = getProgresses(array, duration: duration, options: options)
		for i in 0..<animations.count {
			var (curve1, newDuration) = fullCurve.split(range: progresses[i])
			if let curve2 = animations[i].options.curve {
				curve1 = BezierCurve.between(curve1, curve2)
			}
			array[i].duration = .absolute(duration * newDuration)
			array[i].curve = curve1
		}
	}
	
	private func getProgresses(_ array: [AnimationOptions], duration: Double, options: AnimationOptions) -> [ClosedRange<Double>] {
		guard !array.isEmpty else { return [] }
		guard duration > 0 else {
			return Array(repeating: 0...1, count: array.count)
		}
		var progresses: [ClosedRange<Double>] = []
		for anim in array {
			let end: Double
			if let relative = anim.duration?.relative {
				end = min(1, max(0, relative))
			} else {
				end = (anim.duration?.absolute ?? duration) / duration
			}
			progresses.append(0...end)
		}
		return progresses
	}
	
}

fileprivate final class ParallelCompletion {
	typealias T = (Bool) -> Void
	let common: Int
	var current = 0
	var error = false
	let functions: [(@escaping T) -> Void]
	
	init(_ functions: [(@escaping T) -> Void]) {
		self.common = functions.count
		self.functions = functions
	}
	
	func start(completion: @escaping T) {
		for function in functions {
			function { position in
				guard !self.error else { return }
				self.current += 1
				if self.current >= self.common {
					self.current = 0
					completion(position)
				} else if !position {
					self.error = true
					completion(false)
				}
			}
		}
	}
	
}

fileprivate final class Interactor {
	var prevProgress: Double = 0
}

fileprivate final class Delegates {
	var list: [AnimationDelegate] = []
}

