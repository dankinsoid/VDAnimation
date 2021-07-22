//
//  InteractiveDriver.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

open class InteractiveDriver: UIPercentDrivenInteractiveTransition {
	
	public var completion: ((Bool) -> Void)?
	public weak var vc: UIViewController?
	public weak var delegate: VDTransitioningDelegate?
	public var transitioning: VDAnimatedTransitioning? { delegate?.currentTransitioning }
	private(set) var wasBegun = false
	public var show: Bool = true
	public var startTransition: (UIViewController, Bool) -> Bool
	private var isReversed: Bool {
		transitioning?.transitionType.show != show && transitioning != nil
	}
	
	public init(start: @escaping (UIViewController, Bool) -> Bool) {
		startTransition = start
	}
	
	public init(delegate: VDTransitioningDelegate, startTransition: @escaping (UIViewController, Bool) -> Bool) {
		self.delegate = delegate
		self.startTransition = startTransition
		super.init()
	}
	
	open func begin() {
		guard !wasBegun, let vc = self.vc, !isReversed else { return }
		wasBegun = true
		delegate?.isInteractive = true
		if transitioning != nil {
			transitioning?.animator?.pause()
			return
		}
		let isStarted = startTransition(vc, show)
		wasBegun = isStarted
		delegate?.isInteractive = isStarted
	}
	
	override open func cancel() {
		guard wasBegun else { return }
		super.cancel()
		wasBegun = false
		delegate?.cancel()
	}
	
	override open func finish() {
		guard wasBegun else { return }
		super.finish()
		wasBegun = false
		transitioning?.animator?.stop(at: isReversed ? .start : .end)
		delegate?.isInteractive = false
	}
	
	open func complete(duration: Double?, finish: Bool) {
		guard transitioning?.animator != nil else {
			finish ? self.finish() : self.cancel()
			return
		}
		transitioning?.animator?.add {[weak self] in
			finish && $0 ? self?.finish() : self?.cancel()
		}
		if !finish {
			transitioning?.animator?.play(with: .init(duration: duration.map { .absolute($0) }, isReversed: true))
		} else {
			transitioning?.animator?.play(with: .init(duration: duration.map { .absolute($0) }))
		}
	}
	
	override open func update(_ percentComplete: CGFloat) {
		super.update(percentComplete)
		if transitioning?.animator?.isRunning == true {
			transitioning?.animator?.pause()
		}
		transitioning?.animator?.progress = Double(percentComplete)
	}
}

extension InteractiveDriver {
	
	public static func dismiss(delegate: VDTransitioningDelegate) -> InteractiveDriver {
		present(delegate: delegate, viewController: nil)
	}
	
	public static func present(delegate: VDTransitioningDelegate, viewController: (() -> UIViewController)?) -> InteractiveDriver {
		InteractiveDriver(delegate: delegate) { vc, show in
			if show, let present = viewController?() {
				vc.present(present, animated: true, completion: nil)
				return true
			}
			guard vc.presentingViewController != nil || vc.presentedViewController != nil else { return false }
			vc.dismiss(animated: true, completion: nil)
			return true
		}
	}
	
	public static func pop(delegate: VDTransitioningDelegate) -> InteractiveDriver {
		navigation(delegate: delegate, push: nil)
	}
	
	public static func navigation(delegate: VDTransitioningDelegate, push: (() -> UIViewController)?) -> InteractiveDriver {
		InteractiveDriver(delegate: delegate) { vc, show in
			guard let nc = vc as? UINavigationController else { return false }
			if show, let viewController = push?() {
				nc.pushViewController(viewController, animated: true)
				return true
			}
			guard nc.viewControllers.count > 1 else { return false }
			nc.popViewController(animated: true)
			return true
		}
	}
	
	public static func tab(delegate: VDTransitioningDelegate) -> InteractiveDriver {
		InteractiveDriver(delegate: delegate) { vc, show in
			guard let tb = vc as? UITabBarController else { return false }
			if show {
				guard tb.selectedIndex < (tb.viewControllers ?? []).count - 1 else {
					return false
				}
				tb.selectedIndex += 1
				return true
			} else {
				guard tb.selectedIndex > 0 else {
					return false
				}
				tb.selectedIndex -= 1
				return true
			}
		}
	}
}
