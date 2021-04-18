//
//  ImplicitlyAnimating.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import UIKit

final class ImplicitlyAnimating: NSObject, UIViewImplicitlyAnimating {
	var state: UIViewAnimatingState {
		isRunning ? .active : .inactive
	}
	var isRunning: Bool { delegate.isRunning }
	var isReversed: Bool
	var fractionComplete: CGFloat {
		get { CGFloat(delegate.progress) }
		set {
			if isRunning { delegate.pause() }
			delegate.progress = Double(newValue)
		}
	}
	var delegate: AnimationDelegateProtocol
	
	init(_ delegate: AnimationDelegateProtocol) {
		self.delegate = delegate
		isReversed = delegate.options.isReversed == true
	}
	
	func startAnimation() {
		delegate.play(with: AnimationOptions(isReversed: isReversed))
	}
	
	func startAnimation(afterDelay delay: TimeInterval) {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: startAnimation)
	}
	
	func pauseAnimation() {
		delegate.pause()
	}
	
	func stopAnimation(_ withoutFinishing: Bool) {
		delegate.stop(at: withoutFinishing ? .current : .end)
	}
	
	func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
		switch finalPosition {
		case .end:
			delegate.stop(at: .end)
		case .start:
			delegate.stop(at: .start)
		case .current:
			delegate.stop(at: .current)
		@unknown default:
			delegate.stop(at: .end)
		}
	}
}

extension AnimationDelegateProtocol {
	public func uiViewImplicitlyAnimating() -> UIViewImplicitlyAnimating {
		ImplicitlyAnimating(self)
	}
}
