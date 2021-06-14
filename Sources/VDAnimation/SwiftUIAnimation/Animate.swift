//
//  SwiftUIAnimate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import SwiftUI
import VDKit

///SwiftUI animation
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct Animate: VDAnimationProtocol {
	var block: StateChanges
	private weak var store: AnimationsStore?
	private let id = UUID()
	
	public init(_ store: AnimationsStore? = nil, _ block: @escaping (Double) -> Void) {
		self.init(store, StateChanges(block))
	}
	
	public init(_ store: AnimationsStore? = nil, @ArrayBuilder<StateChanges> _ changes: () -> [StateChanges]) {
		let change = changes()
		self.init(store, StateChanges { p in change.forEach { $0.change(p) }})
	}
	
	init(_ store: AnimationsStore?, _ block: StateChanges) {
		self.store = store
		self.block = block
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		guard let store = store ?? AnimationsStore.current else {
			debugPrint("❗️ SwiftUI animations requires `AnimationsStore`, use `.store(store)` modifier or Animate(store) {...")
			return PrimitiveDelegate(options: options, block: block.change)
		}
		let args = store.animation(for: id)
		return Delegate(
			value: args.0,
			block: block.change,
			options: options,
			publisher: args.1
		)
	}
}

// MARK: Delegates
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Animate {
	
	final class Delegate: AnimationDelegateProtocol {
		
		// MARK: protocol properties
		var isRunning: Bool = false
		var position: AnimationPosition {
			get { .progress(value.1) }
			set { set(progress: newValue.complete, complete: false, animate: false) }
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		
		// MARK: inner properties
		@Bind var value: ((Animation?, () -> Void), Double)
		private let block: (Double) -> Void
		var completions: [(Bool) -> Void] = []
		var bag: [() -> Void] = []
		private var finalValue: Double { options.isReversed == true ? 0 : 1 }
		
		init(value: Bind<((Animation?, () -> Void), Double)>, block: @escaping (Double) -> Void, options: AnimationOptions, publisher: ProgressObservable) {
			self._value = value
			self.options = options
			self.block = block
			bag.append(
				publisher.observe {[weak self] in
					self?.observe($0)
				}
			)
		}
		
		// MARK: protocol methods
		
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
		
		func pause() {
			set(progress: nil, complete: false, animate: true)
		}
		
		func stop(at position: AnimationPosition?) {
			set(progress: position?.complete, complete: true, animate: true)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		// MARK: private methods
		
		private func observe(_ value: Double) {
			guard isRunning, value == finalValue else { return }
			isRunning = false
			DispatchQueue.main.async {
				self.complete(true)
			}
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
		
		private func set(progress: Double?, complete: Bool, animate: Bool) {
			let newValue = progress ?? position.complete
			isRunning = false
			value = ((animate ? .linear(duration: 0) : nil, {[block] in block(newValue) }), newValue)
			if complete {
				self.complete(newValue == finalValue)
			}
		}
		
		deinit {
			pause()
			bag.forEach { $0() }
		}
	}
	
	// MARK: PrimitiveDelegate
	
	final class PrimitiveDelegate: AnimationDelegateProtocol {
		var isRunning = false
		var position: AnimationPosition {
			get { .end }
			set { block(newValue.complete) }
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		private let block: (Double) -> Void
		
		init(options: AnimationOptions, block: @escaping (Double) -> Void) {
			self.options = options
			self.block = block
		}
		
		func play(with options: AnimationOptions) {
			isRunning = true
			self.options = options.or(self.options)
			withAnimation(.bezier(self.options.curve ?? .linear, duration: self.options.duration?.absolute ?? 0)) {
				self.options.isReversed == true ? block(0) : block(1)
			}
		}
		
		func pause() {}
		func stop(at position: AnimationPosition?) {
			isRunning = false
			block(position?.complete ?? 1)
		}
		func add(completion: @escaping (Bool) -> Void) {}
	}
}
