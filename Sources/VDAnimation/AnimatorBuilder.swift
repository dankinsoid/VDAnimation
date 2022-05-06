//
//  AnimationsBuilder.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit
import VDKit

@resultBuilder
public enum AnimationsBuilder {
	
	@inlinable
	public static func buildBlock(_ components: [VDAnimationProtocol]...) -> [VDAnimationProtocol] {
		components.joinedArray()
	}
	
	@inlinable
	public static func buildArray(_ components: [[VDAnimationProtocol]]) -> [VDAnimationProtocol] {
		components.joinedArray()
	}
	
	@inlinable
	public static func buildEither(first component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildEither(second component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildOptional(_ component: [VDAnimationProtocol]?) -> [VDAnimationProtocol] {
		component ?? []
	}
	
	@inlinable
	public static func buildLimitedAvailability(_ component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildExpression(_ expression: VDAnimationProtocol) -> [VDAnimationProtocol] {
		[expression]
	}
}
