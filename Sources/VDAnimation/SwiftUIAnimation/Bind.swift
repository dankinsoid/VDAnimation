//
//  Bind.swift
//  VDTransition
//
//  Created by Данил Войдилов on 19.05.2021.
//

import Foundation

@propertyWrapper
struct Bind<T> {
	let get: () -> T
	let set: (T) -> Void
	var wrappedValue: T {
		get { get() }
		nonmutating set { set(newValue) }
	}
}
