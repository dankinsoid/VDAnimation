//
//  ConstraintAnimation.swift
//  CA
//
//  Created by Daniil on 14.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit
import VDKit
import ConstraintsOperators

public struct ConstraintsAnimation<T>: VDAnimationProtocol {
    let from: () -> [NSLayoutConstraint]
    let to: () -> [NSLayoutConstraint]
    let scale: (Double) -> [NSLayoutConstraint]
    
    init(from: @escaping @autoclosure () -> [NSLayoutConstraint], to: @escaping @autoclosure () -> [NSLayoutConstraint], scale: @escaping (Double) -> [NSLayoutConstraint]) {
        self.from = from
        self.to = to
        self.scale = scale
    }
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(options: options, from: from, to: to, scale: scale)
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isInstant: Bool { inner.isInstant }
		var isRunning: Bool { inner.isRunning }
		var position: AnimationPosition {
			get { inner.position }
			set { set(position: newValue) }
		}
		var inner: AnimationDelegateProtocol
		var options: AnimationOptions { inner.options }
		private var completions: [(Bool) -> Void] = []
		
		let from: () -> [NSLayoutConstraint]
		let to: () -> [NSLayoutConstraint]
		let scale: (Double) -> [NSLayoutConstraint]
		
		init(options: AnimationOptions, from: @escaping () -> [NSLayoutConstraint], to: @escaping () -> [NSLayoutConstraint], scale: @escaping (Double) -> [NSLayoutConstraint]) {
			self.inner = UIViewAnimate {
				let constraint = options.isReversed == true ? from() : to()
				constraint.forEach { $0.didUpdate() }
			}.delegate(with: options)
			self.from = from
			self.to = to
			self.scale = scale
		}
		
		func play(with options: AnimationOptions) {
			inner.play(with: options)
		}
		
		func pause() {
			inner.pause()
		}
		
		func stop(at position: AnimationPosition?) {
			inner.stop(at: position)
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		private func set(position: AnimationPosition) {
			if inner.isRunning {
				inner.position = position
				return
			}
			let state = options.isReversed == true ? position.reversed : position
			let constraint: [NSLayoutConstraint]
			switch state {
			case .start:
				constraint = from()
			case .progress(let k):
				constraint = scale(k)
			case .end:
				constraint = to()
			}
			constraint.forEach { $0.didUpdate() }
		}
	}
}

public struct LayoutGradient<A, B: UILayoutable, C: AttributeConvertable> {
    let from: LayoutAttribute<A, B, C>
    let to: LayoutAttribute<A, B, C>
    let scale: (Double) -> LayoutAttribute<A, B, C>
}
