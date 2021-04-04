//
//  File.swift
//  
//
//  Created by Данил Войдилов on 29.03.2021.
//

import UIKit

extension CAKeyframeAnimation {
	struct Parameters {
		var keyPath: String
		var path: CGPath
	}
}

func start() {
	
	let animation = CAKeyframeAnimation()

	animation.values = []
	animation.path = nil

	animation.rotationMode = .none

	animation.biasValues = []
	animation.calculationMode = .cubic
	animation.tensionValues = []

	animation.continuityValues = []

	animation.duration = 0
	animation.fillMode = .removed
	animation.beginTime = CACurrentMediaTime()
	animation.timeOffset = 0
	animation.speed = 1

	animation.repeatCount = 0
	animation.repeatDuration = 0
	
	animation.keyTimes = [] //0...1, kt[i] = kt[i - 1] + duration / totalDuration
	animation.timingFunctions = []
	
//	CAMediaTimingFunction.init(controlPoints: <#T##Float#>, <#T##c1y: Float##Float#>, <#T##c2x: Float##Float#>, <#T##c2y: Float##Float#>)
//
//	CAAnimationGroup().animations = []
//	CALayer().add(<#T##anim: CAAnimation##CAAnimation#>, forKey: <#T##String?#>)
}

final class Delegate: NSObject, CAAnimationDelegate {
	
	func animationDidStart(_ anim: CAAnimation) {
		
	}
	
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		
	}
}
