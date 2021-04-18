//
//  SwiftUIAnimate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import SwiftUI
import Combine

///SwiftUI animation
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct SwiftUIAnimate: VDAnimationProtocol {
	
	var block: StateChanges
	private weak var store: AnimationsStore.Store?
	private let id = UUID()
    
	init(_ store: AnimationsStore, _ block: StateChanges) {
		self.store = store.store
		self.block = block
	}
    
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		guard let store = store else { return EmptyAnimationDelegate() }
		let args = store.animation(for: id)
		return Delegate(
			value: args.0,
			block: block.change,
			options: options,
			publisher: args.1
		)
	}
}

extension SwiftUIAnimate {
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool = false
		var position: AnimationPosition {
			get { .progress(value.1) }
			set {
				set(progress: newValue.complete, complete: false, animate: false)
			}
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		@Binding var value: ((Animation?, () -> Void), Double)
		private let block: (Double) -> Void
		var completions: [(Bool) -> Void] = []
		var bag: [() -> Void] = []
		private var finalValue: Double { options.isReversed == true ? 0 : 1 }
		
		deinit {
			pause()
			bag.forEach { $0() }
		}
		
		init(value: Binding<((Animation?, () -> Void), Double)>, block: @escaping (Double) -> Void, options: AnimationOptions, publisher: ProgressObservable) {
			self._value = value
			self.options = options
			self.block = block
			
			bag.append(
				publisher.observe {[weak self] in
					self?.observe($0)
				}
			)
		}
		
		private func observe(_ value: Double) {
			guard isRunning, value == finalValue else { return }
			isRunning = false
			DispatchQueue.main.async {
				self.complete(true)
			}
		}
		
		func play(with options: AnimationOptions) {
			if isRunning {
				if options == .empty {
					return
				}
				pause()
			}
			self.options = options.or(self.options)
			play()
		}
		
		private func play() {
			isRunning = true
			let current = value.1
			if options.duration?.absolute ?? 0 == 0 ||
				current == 1 && options.isReversed != true ||
				current == 0 && options.isReversed == true {
				zeroPlay()
				return
			}
			let params: (BezierCurve, Double)
			if options.isReversed == true {
				let _params = (options.curve ?? .linear).split(range: 0...max(0, current))
				params = (_params.0.reversed, _params.1)
			} else {
				params = (options.curve ?? .linear).split(range: min(1, current)...1)
			}
			if params.1 == 0 {
				zeroPlay()
				return
			}
			let animation = Animation.bezier(params.0, duration: params.1 * (options.duration?.absolute ?? 0))
			let percent: Double = options.isReversed == true ? 0 : 1
			value = ((nil, {[block] in block(current) }), current)
			value = ((animation, {[block] in block(percent) }), percent)
		}
		
		private func zeroPlay() {
			set(progress: options.isReversed == true ? 0 : 1, complete: true, animate: false)
		}
		
		private func complete(_ completed: Bool) {
			isRunning = false
			completions.forEach {
				$0(completed)
			}
		}
		
		func pause() {
			set(progress: nil, complete: false, animate: true)
		}
		
		func stop(at position: AnimationPosition?) {
			set(progress: position?.complete, complete: true, animate: true)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		private func set(progress: Double?, complete: Bool, animate: Bool) {
			let newValue = progress ?? value.1
			isRunning = false
			value = ((animate ? .linear(duration: 0) : nil, {[block] in block(newValue) }), newValue)
			if complete {
				self.complete(newValue == finalValue)
			}
		}
	}
}
