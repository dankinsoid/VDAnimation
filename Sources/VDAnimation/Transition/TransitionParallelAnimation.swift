//
//  TransitionParallelAnimation.swift
//  VDTransition
//
//  Created by Данил Войдилов on 23.04.2021.
//

import Foundation

public struct TransitionParallelAnimation {
	
	public var animation: (VDTransitionContext) -> VDAnimationProtocol
	
	public init(_ animation: @escaping (VDTransitionContext) -> VDAnimationProtocol) {
		self.animation = animation
	}
	
	public static func symmetric(_ animation: @escaping (VDTransitionContext) -> VDAnimationProtocol) -> TransitionParallelAnimation {
		TransitionParallelAnimation {
			if $0.type.show {
				return animation($0)
			} else {
				return animation($0).reversed()
			}
		}
	}
}
