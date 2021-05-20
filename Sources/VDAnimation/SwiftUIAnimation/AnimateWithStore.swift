//
//  AnimateWithStore.swift
//  VDTransition
//
//  Created by Данил Войдилов on 20.05.2021.
//

import Foundation
import SwiftUI

public struct AnimateWithStore: VDAnimationProtocol {
	
	weak var store: AnimationsStore?
	let animation: VDAnimationProtocol
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		guard let store = store ?? AnimationsStore.current else {
			return EmptyAnimationDelegate()
		}
		let current = AnimationsStore.current
		AnimationsStore.current = store
		let result = animation.delegate(with: options)
		AnimationsStore.current = current
		return result
	}
}

extension VDAnimationProtocol {
	public func store(_ store: AnimationsStore) -> AnimateWithStore {
		AnimateWithStore(store: store, animation: self)
	}
}
