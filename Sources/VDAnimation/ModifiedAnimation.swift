//
//  ModifiedAnimation.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public struct ModifiedAnimation: VDAnimationProtocol {
	var options: AnimationOptions
	let animation: VDAnimationProtocol
	var chain: ValueChaining<ModifiedAnimation> { ValueChaining(self) }
    
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		animation.delegate(with: options.or(self.options))
	}
}
