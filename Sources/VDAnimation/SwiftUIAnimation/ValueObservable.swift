//
//  ProgressObserver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import Foundation
import SwiftUI

final class ValueObservable<Value: Equatable> {
	private var observers: [UUID: (Value, Value) -> Void] = [:]
	var value: Value {
		didSet {
			observers.forEach { $0.value(oldValue, value) }
		}
	}
	
	init(_ value: Value) {
		self.value = value
	}
	
	@discardableResult
	func observe(_ observer: @escaping (Value, Value) -> Void) -> () -> Void {
		let id = UUID()
		observers[id] = observer
		observer(value, value)
		return {
			self.observers[id] = nil
		}
	}
}

final class ProgressObservable {
	let id: UUID
	let base: ValueObservable<AnimationModifier.AnimatableData>
	var value: Double? {
		get { base.value.values[id] }
		set { base.value.values[id] = newValue }
	}
	
	init(id: UUID, value: ValueObservable<AnimationModifier.AnimatableData>) {
		self.id = id
		self.base = value
	}
	
	@discardableResult
	func observe(_ observer: @escaping (Double) -> Void) -> () -> Void {
		if let old = value {
			observer(old)
		}
		return base.observe {[id] in
			if let progress = $1.values[id], $0.values[id] != $1.values[id] {
				observer(progress)
			}
		}
	}
}

final class ValueSubject<Value> {
	private var observers: [UUID: (Value) -> Void] = [:]
	
	@discardableResult
	func observe(_ observer: @escaping (Value) -> Void) -> () -> Void {
		let id = UUID()
		observers[id] = observer
		return {
			self.observers[id] = nil
		}
	}

	func send(_ value: Value) {
		observers.forEach { $0.value(value) }
	}
}

extension View {
	
	func onReceive<T>(_ subject: ValueSubject<T>, observer: @escaping (T) -> Void) -> some View {
		let wrapper = Wrapper<T>()
		return onAppear {
			wrapper.observer = subject.observe(observer)
		}
		.onDisappear {
			wrapper.observer?()
			wrapper.observer = nil
		}
	}
}

private final class Wrapper<T> {
	var observer: (() -> Void)?
}