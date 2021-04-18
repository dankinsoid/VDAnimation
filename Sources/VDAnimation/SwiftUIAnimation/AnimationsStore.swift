//
//  AnimationsStore.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import SwiftUI
import Combine

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
}

extension AnimationsStore {
	final class Store {
		var animation: VDAnimationProtocol?
		lazy var delegate: AnimationDelegateProtocol? = animation?.delegate()
		
		let valueSubject = ValueObservable<AnimationModifier.AnimatableData>(.zero)
		let valueBinder = ValueSubject<((Animation?, () -> Void), AnimationModifier.AnimatableData)>()
		
		func animation(for id: UUID) -> (Binding<((Animation?, () -> Void), Double)>, ProgressObservable) {
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
				ProgressObservable(id: id, value: valueSubject)
			)
		}
	}
}

extension AnimationsStore {
	
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
extension View {
	public func with(_ store: AnimationsStore) -> some View {
		AnimationsStore.Wrapper(store: store.store, content: self)
	}
	
	public func with(_ store: AnimationsStore, animation: VDAnimationProtocol) -> some View {
		with(store) { animation }
	}
	
	public func with(_ store: AnimationsStore, animation: () -> VDAnimationProtocol) -> some View {
		store.store.animation = animation()
		return AnimationsStore.Wrapper(store: store.store, content: self)
	}
}
