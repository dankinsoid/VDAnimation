//
//  File.swift
//  
//
//  Created by Данил Войдилов on 29.03.2021.
//

import UIKit
import VDKit

///UIKit animation
struct UIKitAnimation: ClosureAnimation {
	
	let block: () -> Void
	let springTiming: UISpringTimingParameters?
	
	init(_ block: @escaping () -> Void, spring: UISpringTimingParameters?) {
		self.block = block
		springTiming = spring
	}
	
	init(_ closure: @escaping () -> Void) {
		block = closure
		springTiming = nil
	}
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		let provider = VDTimingProvider(bezier: options.curve, spring: springTiming)
		let animator = VDViewAnimator(duration: options.duration?.absolute ?? 0, timingParameters: provider)
		animator.animationOptions = options
		animator.addAnimations(block)
		
		animator.pausesOnCompletion = !(options.complete ?? true)
		if options.isReversed == true {
			animator.isReversed = true
		}
		return animator
	}
}
