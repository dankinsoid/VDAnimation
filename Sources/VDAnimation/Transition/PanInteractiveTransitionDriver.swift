//
//  PanInteractiveTransitionDriver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

open class PanInteractiveTransitionDriver: NSObject {
	public let transition: VDAnimationTransition
	public let recognizer: UIPanGestureRecognizer
	public let update: (UIPanGestureRecognizer) -> CGFloat
	public let edge: Edges
	private var didStart = false
	
	public init(recognizer: UIPanGestureRecognizer, edge: Edges, transition: VDAnimationTransition, update: @escaping (UIPanGestureRecognizer) -> CGFloat) {
		self.recognizer = recognizer
		self.transition = transition
		self.update = update
		self.edge = edge
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
			guard !didStart else { return }
			let minOffset: CGFloat = 36.7
			switch edge {
			case .top:
				guard sender.location(in: sender.view).y < minOffset else { return }
			case .leading:
				guard sender.location(in: sender.view).x < minOffset else { return }
			case .bottom:
				guard ((sender.view?.frame.height ?? 0) - sender.location(in: sender.view).y) < minOffset else { return }
			case .trailing:
				guard ((sender.view?.frame.width ?? 0) - sender.location(in: sender.view).x) < minOffset else { return }
			}
			didStart = true
			transition.begin()
		case .changed:
			guard didStart else { return }
			transition.update(update(recognizer))
		case .ended:
			guard didStart else { return }
			didStart = false
			let velocity = sender.velocity(in: sender.view).x
			let finish = (velocity > 0) == (edge == .leading || edge == .top)
			let final = finish ? (sender.view?.frame.width ?? 0) : 0
			let maxTime = transition.transitioning.duration * Double(finish ? 1 - transition.percentComplete : transition.percentComplete)
			let time = velocity == 0 ? maxTime : Double(final / abs(velocity))
			transition.complete(duration: min(maxTime, time), finish: finish)
		case .cancelled, .failed:
			guard didStart else { return }
			didStart = false
			transition.cancel()
		@unknown default:
			break
		}
	}
}
