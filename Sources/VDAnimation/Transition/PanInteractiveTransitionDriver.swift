//
//  PanInteractiveTransitionDriver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit
import VDKit

open class PanInteractiveTransitionDriver: InteractiveDriver {
	public let recognizer: UIPanGestureRecognizer
	public let edge: Edges
	private var didStart = false
	
	public init(recognizer: UIPanGestureRecognizer, edge: Edges, delegate: VDTransitioningDelegate, startTransition: @escaping (UIViewController, Bool) -> Bool) {
		self.recognizer = recognizer
		self.edge = edge
		super.init(delegate: delegate, startTransition: startTransition)
		prepare()
	}
	
	private func prepare() {
		recognizer.isEnabled = true
		recognizer.addTarget(self, action: #selector(recognised))
	}
	
	private var percent: CGFloat {
		switch edge {
		case .top:
			return recognizer.location(in: recognizer.view).y / (recognizer.view?.frame.height ?? 1)
		case .leading:
			return recognizer.location(in: recognizer.view).x / (recognizer.view?.frame.width ?? 1)
		case .bottom:
			return 1 - recognizer.location(in: recognizer.view).y / (recognizer.view?.frame.height ?? 1)
		case .trailing:
			return 1 - recognizer.location(in: recognizer.view).x / (recognizer.view?.frame.width ?? 1)
		}
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
			update(percent)
		case .ended:
			guard didStart else { return }
			didStart = false
			let velocity = sender.velocity(in: sender.view).x
			let finish = (velocity > 0) == (edge == .leading || edge == .top)
			let final = finish ? (sender.view?.frame.width ?? 0) : 0
			let maxTime = (transitioning?.duration ?? 0) * Double(finish ? 1 - percentComplete : percentComplete)
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
