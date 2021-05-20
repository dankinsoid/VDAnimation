//
//  VDTimingProvider.swift
//  VDTransition
//
//  Created by Данил Войдилов on 20.05.2021.
//

import UIKit

@objc(_TtC15SuperAnimationsVDTimingProvider)
class VDTimingProvider: NSObject, UITimingCurveProvider {
	let timingCurveType: UITimingCurveType
	let cubicTimingParameters: UICubicTimingParameters?
	let springTimingParameters: UISpringTimingParameters?
	
	init(bezier: BezierCurve?, spring: UISpringTimingParameters?) {
		var isBuiltin = false
		if let bezier = bezier {
			if let builtin = bezier.builtin {
				cubicTimingParameters = UICubicTimingParameters(animationCurve: builtin)
				isBuiltin = true
			} else {
				cubicTimingParameters = UICubicTimingParameters(controlPoint1: bezier.point1, controlPoint2: bezier.point2)
			}
		} else if spring == nil {
			cubicTimingParameters = UICubicTimingParameters(animationCurve: .linear)
			isBuiltin = true
		} else {
			cubicTimingParameters = nil
		}
		springTimingParameters = spring
		switch (bezier, spring) {
		case (.some, .some): timingCurveType = .composed
		case (.some, .none): timingCurveType = isBuiltin ? .builtin : .cubic
		case (.none, .some): timingCurveType = .spring
		case (.none, .none): timingCurveType = .cubic
		}
	}
	
	init(timing: UITimingCurveType, cubic: UICubicTimingParameters?, spring: UISpringTimingParameters?) {
		self.timingCurveType = timing
		self.cubicTimingParameters = cubic
		self.springTimingParameters = spring
	}
	
	required init?(coder: NSCoder) {
		timingCurveType = UITimingCurveType(rawValue: coder.decodeInteger(forKey: Keys.timingCurveType)) ?? .cubic
		cubicTimingParameters = coder.decodeObject(of: UICubicTimingParameters.self, forKey: Keys.cubicTimingParameters)
		springTimingParameters = coder.decodeObject(of: UISpringTimingParameters.self, forKey: Keys.springTimingParameters)
	}
	
	func encode(with coder: NSCoder) {
		coder.encode(timingCurveType.rawValue, forKey: Keys.timingCurveType)
		coder.encode(cubicTimingParameters, forKey: Keys.cubicTimingParameters)
		coder.encode(springTimingParameters, forKey: Keys.springTimingParameters)
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return VDTimingProvider(timing: timingCurveType, cubic: cubicTimingParameters, spring: springTimingParameters)
	}
	
	fileprivate struct Keys {
		static let timingCurveType = "timingCurveType"
		static let cubicTimingParameters = "cubicTimingParameters"
		static let springTimingParameters = "springTimingParameters"
	}
}

fileprivate final class Animator {
	var animator: VDViewAnimator?
}

fileprivate final class Interactor {
	var animator: VDViewAnimator?
	let animation: () -> Void
	var position = UIViewAnimatingPosition.start
	
	init(_ block: @escaping () -> Void) {
		animation = block
	}
	
	deinit {
		reset(at: .end)
	}
	
	func reset(at finalPosition: UIViewAnimatingPosition) {
		animator?.finishAnimation(at: finalPosition)
		animator = nil
		position = finalPosition
	}
	
	func set(state: AnimationPosition) {
		switch state {
		case .start:
			guard position != .start else { return }
			reset(at: .start)
		case .progress(let k):
			create().fractionComplete = CGFloat(k)
		case .end:
			guard position != .end else { return }
			_ = create()
			reset(at: .end)
		}
	}
	
	func create() -> VDViewAnimator {
		if let result = animator {
			return result
		}
		let result = VDViewAnimator()
		result.addAnimations(animation)
		animator = result
		return result
	}
}
