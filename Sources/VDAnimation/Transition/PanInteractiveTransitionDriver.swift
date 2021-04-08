//
//  PanInteractiveTransitionDriver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import ConstraintsOperators

open class PanInteractiveTransitionDriver: VDPercentDrivenTransition {
	public let recognizer: UIPanGestureRecognizer
	public let edge: Edges
	private var didStart = false
	
	public init(recognizer: UIPanGestureRecognizer, edge: Edges, transitioning: VDAnimatedTransitioning, delegate: VDTransitioningDelegate) {
		self.recognizer = recognizer
		self.edge = edge
		super.init(transitioning: transitioning, delegate: delegate)
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
			begin()
			didStart = true
		case .changed:
			guard didStart else { return }
			let percent: CGFloat
			switch edge {
			case .top:
				percent = sender.location(in: sender.view).y / (sender.view?.frame.height ?? 1)
			case .leading:
				percent = sender.location(in: sender.view).x / (sender.view?.frame.width ?? 1)
			case .bottom:
				percent = 1 - sender.location(in: sender.view).y / (sender.view?.frame.height ?? 1)
			case .trailing:
				percent = 1 - sender.location(in: sender.view).x / (sender.view?.frame.width ?? 1)
			}
			update(percent)
		case .ended:
			guard didStart else { return }
			didStart = false
			let velocity = sender.velocity(in: sender.view).x
			let finish = (velocity > 0) == (edge == .leading || edge == .top)
			let final = finish ? (sender.view?.frame.width ?? 0) : 0
			let maxTime = transitioning.duration * Double(finish ? 1 - percentComplete : percentComplete)
			let time = velocity == 0 ? maxTime : Double(final / abs(velocity))
			complete(duration: min(maxTime, time), finish: finish)
		case .cancelled, .failed:
			guard didStart else { return }
			didStart = false
			cancel()
		@unknown default:
			break
		}
	}
}
