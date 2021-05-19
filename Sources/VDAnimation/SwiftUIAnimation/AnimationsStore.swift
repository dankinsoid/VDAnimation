//
//  AnimationsStore.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import SwiftUI
import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public final class AnimationsStore: AnimationDelegateProtocol, ObservableObject {
	
	var animation: VDAnimationProtocol? {
		didSet { if oldValue == nil { _delegate.reset() } }
	}
	
	@LazyProperty var delegate: AnimationDelegateProtocol?
	
	public var isRunning: Bool {
		get { delegate?.isRunning ?? false }
		set { newValue ? delegate?.play() : delegate?.pause() }
	}
	public var isInstant: Bool { delegate?.isInstant ?? false }
	
	public var position: AnimationPosition {
		get { delegate?.position ?? .start }
		set { delegate?.position = newValue }
	}
	
	public var options: AnimationOptions { delegate?.options ?? .empty }
	
	public init() {
		_delegate = .init {[weak self] in
			self?.animation?.delegate()
		}
	}
	
	let valueSubject = ValueObservable<AnimationModifier.AnimatableData>(.zero)
	let valueBinder = ValueSubject<((Animation?, () -> Void), AnimationModifier.AnimatableData)>()
	
	public func pause() {
		delegate?.pause()
	}
	
	public func play(with options: AnimationOptions) {
		delegate?.play(with: options)
	}
	
	public func add(completion: @escaping (Bool) -> Void) {
		delegate?.add(completion: completion)
	}
	
	public func stop(at position: AnimationPosition?) {
		delegate?.stop(at: position)
	}
	
	func animation(for id: UUID) -> (Bind<((Animation?, () -> Void), Double)>, ProgressObservable) {
		let binder = Bind<((Animation?, () -> Void), Double)>(
			get: {[weak self] in
				((nil, {}), self?.valueSubject.value.values[id] ?? 0)
			},
			set: {[weak self] in
				var new = self?.valueSubject.value ?? .init()
				new.values[id] = $0.1
				self?.valueBinder.send(($0.0, new))
			}
		)
		return (
			binder,
			ProgressObservable(id: id, value: valueSubject)
		)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnimationsStore {
	
	struct Wrapper<Content: View>: View {
		let store: AnimationsStore
		let content: Content
		@State private var progress: AnimationModifier.AnimatableData
		
		init(store: AnimationsStore, content: Content) {
			self.store = store
			self.content = content
			self._progress = .init(initialValue: store.valueSubject.value)
		}
		
		var body: some View {
			content
				.onReceive(store.valueBinder) { args in
					if let animation = args.0.0 {
						guard progress != args.1 else { return }
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
extension View {
	public func with(_ store: AnimationsStore) -> some View {
		AnimationsStore.Wrapper(store: store, content: self)
	}
	
	public func with(_ store: AnimationsStore, animation: VDAnimationProtocol) -> some View {
		with(store) { animation }
	}
	
	public func with(_ store: AnimationsStore, animation: () -> VDAnimationProtocol) -> some View {
		store.animation = animation()
		return AnimationsStore.Wrapper(store: store, content: self)
	}
}
