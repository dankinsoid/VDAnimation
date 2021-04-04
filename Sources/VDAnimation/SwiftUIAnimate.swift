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
	
	private let block: StateChanges
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
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool = false
		var position: AnimationPosition {
			get { .progress(options.isReversed == true ? 1 - value.1 : value.1) }
			set {
				set(progress: newValue.complete, complete: false, animate: false)
			}
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		@Binding var value: ((Animation?, () -> Void), Double)
		private let block: (Double) -> Void
		var completions: [(Bool) -> Void] = []
		var bag: Set<AnyCancellable> = []
		private var finalValue: Double { options.isReversed == true ? 0 : 1 }
		
		deinit {
			pause()
		}
		
		init<P: Publisher>(value: Binding<((Animation?, () -> Void), Double)>, block: @escaping (Double) -> Void, options: AnimationOptions, publisher: P) where P.Output == Double, P.Failure == Never {
			self._value = value
			self.options = options
			self.block = block
			
			publisher.sink {[weak self] in
				self?.observe($0)
			}
			.store(in: &bag)
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
//			DispatchQueue.main.async {[self] in
				let params: (BezierCurve, Double)
				if options.isReversed == true {
					let _params = (options.curve ?? .linear).split(range: 0...max(0, value.1))
					params = (_params.0.reversed, _params.1)
				} else {
					params = (options.curve ?? .linear).split(range: min(1, value.1)...1)
				}
				print(value.1, params.1, options.isReversed, options.duration)
				let animation = Animation.bezier(params.0, duration: params.1 * (options.duration?.absolute ?? 0))
				let percent: Double = options.isReversed == true ? 0 : 1
				value = ((animation, {[block] in block(percent) }), percent)
//			}
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
			let newValue = progress.map { options.isReversed == true ? 1 - $0 : $0 } ?? value.1
			isRunning = false
			value = ((animate ? .linear(duration: 0) : nil, {[block] in block(newValue) }), newValue)
			if complete {
				self.complete(newValue == finalValue)
			}
		}
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: Animatable {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		SwiftUIAnimate(store, self.change(gradient))
	}
	
	public func to(_ value: Value) -> StateChanges {
		self.change(wrappedValue...value)
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges(change: { wrappedValue = gradient.at($0) })
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ScalableConvertable {
	
	public func animate(_ store: AnimationsStore, _ gradient: Gradient<Value>) -> VDAnimationProtocol {
		SwiftUIAnimate(store, self.change(gradient))
	}
	
	public func to(_ value: Value) -> StateChanges {
		self.change(wrappedValue...value)
	}
	
	public func change(_ gradient: Gradient<Value>) -> StateChanges {
		StateChanges(change: { wrappedValue = gradient.at($0) })
	}
}

infix operator =~: AssignmentPrecedence

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: Animatable>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	lhs.change(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public func =~<V: ScalableConvertable>(_ lhs: Binding<V>, _ rhs: Gradient<V>) -> StateChanges {
	lhs.change(rhs)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct StateChanges {
	let change: (Double) -> Void
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
	public func with(_ store: AnimationsStore) -> some View {
		AnimationsStore.Wrapper(store: store.store, content: self)
	}
	
	public func with(_ store: AnimationsStore, animation: () -> VDAnimationProtocol) -> some View {
		store.store.animation = animation()
		return AnimationsStore.Wrapper(store: store.store, content: self)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct AnimationsStore: AnimationDelegateProtocol {
	let store = Store()
	
	public var isRunning: Bool { store.delegate?.isRunning ?? false }
	public var isInstant: Bool { store.delegate?.isInstant ?? false }
	
	public var position: AnimationPosition {
		get {
			store.delegate?.position ?? .start
		}
		nonmutating set {
			store.delegate?.position = newValue
		}
	}
	
	public var options: AnimationOptions { store.delegate?.options ?? .empty }
	
	public init() {}
	
	public func pause() {
		store.delegate?.pause()
	}
	
	public func play(with options: AnimationOptions) {
		store.delegate?.play(with: options)
	}
	
	public func add(completion: @escaping (Bool) -> Void) {
		store.delegate?.add(completion: completion)
	}
	
	public func stop(at position: AnimationPosition?) {
		store.delegate?.stop(at: position)
	}
	
	final class Store {
		var animation: VDAnimationProtocol?
		lazy var delegate: AnimationDelegateProtocol? = animation?.delegate()
		
		let valueSubject = CurrentValueSubject<AnimationModifier.AnimatableData, Never>(.zero)
		let valueBinder = PassthroughSubject<((Animation?, () -> Void), AnimationModifier.AnimatableData), Never>()
		
		func animation(for id: UUID) -> (Binding<((Animation?, () -> Void), Double)>, AnyPublisher<Double, Never>) {
			let binder = Binding<((Animation?, () -> Void), Double)>(
				get: {[valueSubject] in
					((nil, {}), valueSubject.value.values[id] ?? 0)
				},
				set: {[valueSubject, valueBinder] in
					var new = valueSubject.value
					new.values[id] = $0.1
					valueBinder.send(($0.0, new))
				}
			)
			return (
				binder,
				valueSubject
					.compactMap({ $0.values[id] })
					.removeDuplicates()
					.eraseToAnyPublisher()
			)
		}
	}
	
	struct Wrapper<Content: View>: View {
		let store: Store
		let content: Content
		@State private var progress: AnimationModifier.AnimatableData
		
		init(store: Store, content: Content) {
			self.store = store
			self.content = content
			self._progress = .init(initialValue: store.valueSubject.value)
		}
		
		var body: some View {
			content
				.onReceive(store.valueBinder) { args in
					if let animation = args.0.0 {
						withAnimation(animation) {
							progress = args.1
							args.0.1()
						}
					} else {
						store.valueSubject.value = args.1
						progress = args.1
						args.0.1()
					}
				}
				.modifier(
					AnimationModifier(valueSubject: store.valueSubject, current: progress)
				)
		}
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct AnimationModifier: AnimatableModifier {
	let valueSubject: CurrentValueSubject<AnimatableData, Never>
	
	var animatableData: AnimatableData {
		didSet {
			valueSubject.value = animatableData
		}
	}
	
	init(valueSubject: CurrentValueSubject<AnimatableData, Never>, current: AnimatableData) {
		animatableData = current
		self.valueSubject = valueSubject
	}
	
	func body(content: Content) -> some View {
		content
	}
	
	struct AnimatableData: VectorArithmetic {
		static var zero: AnimationModifier.AnimatableData { .init() }
		var values: [UUID: Double]
		var magnitudeSquared: Double {
			(values.reduce(0, { $0 + $1.value }) / Double(max(1, values.count))).magnitudeSquared
		}
		
		init(_ values: [UUID: Double] = [:]) {
			self.values = values
		}
		
		mutating func scale(by rhs: Double) {
			values = values.mapValues { $0 * rhs }
		}
		
		static func +(lhs: AnimationModifier.AnimatableData, rhs: AnimationModifier.AnimatableData) -> AnimationModifier.AnimatableData {
			.init(lhs.values.union(with: rhs.values, uniquingKeysWith: +))
		}
		
		static func -(lhs: AnimationModifier.AnimatableData, rhs: AnimationModifier.AnimatableData) -> AnimationModifier.AnimatableData {
			.init(lhs.values.union(with: rhs.values, uniquingKeysWith: -))
		}
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Animation {
	public static func bezier(_ bezier: BezierCurve, duration: Double = 0.35) -> Animation {
		.timingCurve(Double(bezier.point1.x), Double(bezier.point1.y), Double(bezier.point2.x), Double(bezier.point2.y), duration: duration)
	}
	
	public static func with(options: AnimationOptions) -> Animation {
		.bezier(options.curve ?? .linear, duration: options.duration?.absolute ?? 0.35)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Color: Animatable {
	public var scaleData: UIColor.ScaledData {
		if #available(iOS 14.0, *) {
			return UIColor(self).scaleData
		} else {
			return components()
		}
	}
	
	public var animatableData: UIColor.ScaledData {
		get { scaleData }
		set { self = .init(scaleData: newValue) }
	}
	
	public init(scaleData: UIColor.ScaledData) {
		self = Color(UIColor(scaleData: scaleData))
	}
	
	private func components() -> UIColor.ScaledData {
		let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
		var hexNumber: UInt64 = 0
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
		
		let result = scanner.scanHexInt64(&hexNumber)
		if result {
			r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
			g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
			b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
			a = CGFloat(hexNumber & 0x000000ff) / 255
		}
		return UIColor.ScaledData(red: r, green: g, blue: b, alpha: a)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIColor.ScaledData: VectorArithmetic {
	
	public mutating func scale(by rhs: Double) {
		self = scaled(by: rhs)
	}
	
	public var magnitudeSquared: Double {
		AnimatablePair(AnimatablePair(red, blue), AnimatablePair(green, alpha)).magnitudeSquared
	}
}
