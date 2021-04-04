//
//  LazyProperty.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import Foundation

@propertyWrapper
public final class LazyProperty<T> {
	let get: () -> T
	private var value: T?
	
	public var wrappedValue: T {
		get {
			if value == nil {
				value = get()
			}
			return value ?? get()
		}
		set {
			value = newValue
		}
	}
	
	public init(_ get: @escaping () -> T) {
		self.get = get
	}
	
	public init(_ get: @escaping @autoclosure () -> T) {
		self.get = get
	}
	
	public func reset() {
		value = nil
	}
	
	public func update() {
		value = get()
	}
}
