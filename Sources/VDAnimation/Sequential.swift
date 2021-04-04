//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation
import VDKit

public struct Sequential: VDAnimationProtocol {
	private let animations: [VDAnimationProtocol]
	
	public init(_ animations: [VDAnimationProtocol]) {
		self.animations = animations
	}
	
	public init(_ animations: VDAnimationProtocol...) {
		self = .init(animations)
	}
	
	public init(@AnimationsBuilder _ animations: () -> [VDAnimationProtocol]) {
		self = .init(animations())
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		if animations.count == 1 {
			return animations[0].delegate(with: options)
		} else if animations.isEmpty {
			return EmptyAnimationDelegate()
		} else {
			return SequentialDelegate(animations: animations.map { $0.delegate(with: .empty) }, options: options)
		}
	}
}
