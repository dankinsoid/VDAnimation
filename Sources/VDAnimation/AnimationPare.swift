//
//  AnimationPare.swift
//  VDTransition
//
//  Created by Данил Войдилов on 30.03.2021.
//

import Foundation

public struct AnimationPare<L, R> {
	public var _0: L
	public var _1: R
	
	public init(_ l: L, _ r: R) {
		_0 = l
		_1 = r
	}
}



protocol An {
	associatedtype Delegate: AnimationDelegateProtocol
	func delegate() -> Delegate
}

protocol WA: AnimationDelegateProtocol {}

protocol AA: An {
	override associatedtype Delegate: WA
}
