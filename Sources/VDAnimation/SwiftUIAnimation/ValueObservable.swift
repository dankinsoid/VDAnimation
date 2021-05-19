//
//  ProgressObserver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import Foundation
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
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

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
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

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
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

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
	
	func onReceive<T>(_ subject: ValueSubject<T>, observer: @escaping (T) -> Void) -> some View {
		ValueSubjectView(content: self, subject: subject, observer: observer)
	}
}

private struct ValueSubjectView<Content: View, T>: View {
	let content: Content
	let subject: ValueSubject<T>
	let observer: (T) -> Void
	@StateObject var wrapper = Wrapper<T>()
	
	var body: some View {
		content
			.onAppear {
				wrapper.observer = subject.observe(observer)
			}
			.onDisappear {
				wrapper.observer?()
				wrapper.observer = nil
			}
	}
}

private final class Wrapper<T>: ObservableObject {
	var observer: (() -> Void)?
}
