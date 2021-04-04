//
//  PanInteractiveTransitionDriver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

open class PanInteractiveTransitionDriver: NSObject {
	public let transition: VDAnimationTransition
	public let recognizer: UIPanGestureRecognizer
	public let update: (UIPanGestureRecognizer) -> CGFloat
	
	public init(recognizer: UIPanGestureRecognizer, transition: VDAnimationTransition, update: @escaping (UIPanGestureRecognizer) -> CGFloat) {
		self.recognizer = recognizer
		self.transition = transition
		self.update = update
		super.init()
		prepare()
	}
	
	private func prepare() {
		recognizer.isEnabled = true
		recognizer.addTarget(self, action: #selector(recognised))
	}
	
	@objc
	private func recognised(sender: UIPanGestureRecognizer) {
		switch sender.state {
		case .possible:
			break
		case .began:
			transition.begin()
		case .changed:
			transition.update(update(recognizer))
		case .ended:
			if transition.percentComplete >= 0.5 {
				transition.finish()
			} else {
				transition.cancel()
			}
		case .cancelled, .failed:
			transition.cancel()
		@unknown default:
			break
		}
	}
}
