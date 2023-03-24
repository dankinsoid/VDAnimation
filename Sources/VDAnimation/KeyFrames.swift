import UIKit

//func start() {
//
//	let animation = CAKeyframeAnimation()
//
//	animation.values = []
//	animation.path = nil
//
//	animation.rotationMode = .none
//
//	animation.biasValues = []
//	animation.calculationMode = .cubic
//	animation.tensionValues = []
//
//	animation.continuityValues = []
//
//	animation.duration = 0
//	animation.fillMode = .removed
//	animation.beginTime = CACurrentMediaTime()
//
//	animation.timeOffset = 0
//	animation.speed = 1
//
//	animation.repeatCount = 0
//	animation.repeatDuration = 0
//
//	animation.keyTimes = [] //0...1, kt[i] = kt[i - 1] + duration / totalDuration
//	animation.timingFunctions = []
//
//
//	CAAnimationGroup().animations = []
//}

struct LayerAnimation<A: CAAnimation>: VDAnimationProtocol {
	public var layer: CALayer
	public var animation: A
	
	public init(_ animation: A, for layer: CALayer) {
		self.animation = animation
		self.layer = layer
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		Delegate(animation: animation, layer: layer, options: options)
	}
}

extension LayerAnimation {
	
	final class Delegate: NSObject, AnimationDelegateProtocol, CAAnimationDelegate {
		var layer: CALayer
		var animation: CAAnimationGroup
		var isRunning: Bool { layer.animation(forKey: id) != nil && animation.speed != 0 }
		var position: AnimationPosition {
			get { .progress(layer.presentation()?.vdAnimationProgress ?? 0) }
			set {
				animation.delegate = nil
				animation.speed = 0
				set(newValue.complete)
				if layer.animation(forKey: id) == nil {
					layer.add(animation, forKey: id)
				}
			}
		}
		var options: AnimationOptions
		var isInstant: Bool { false }
		let id = UUID().uuidString
		private var completions: [(Bool) -> Void] = []
		private var speed: Float { options.isReversed == true ? -1 : 1 }
		
		init(animation: A, layer: CALayer, options: AnimationOptions) {
			self.options = options
			self.animation = Delegate.group(for: animation)
			self.layer = layer
			super.init()
		}
		
		func play(with options: AnimationOptions) {
			let new = options.or(self.options)
			if new == self.options, layer.animation(forKey: id) != nil, speed == 0 {
				layer.speed = speed
				return
			}
			self.options = new
			play()
		}
		
		private func play() {
			animation.delegate = nil
			layer.removeAnimation(forKey: id)
			animation.duration = options.duration?.absolute ?? 0
			animation.timingFunction = options.curve.map {
				CAMediaTimingFunction(controlPoints: Float($0.point1.x), Float($0.point1.y), Float($0.point2.x), Float($0.point2.y))
			}
			animation.speed = speed
			animation.delegate = speed == 0 ? nil : self
			layer.add(animation, forKey: id)
		}
		
		func pause() {
			animation.speed = 0
		}
		
		func stop(at position: AnimationPosition?) {
			animation.speed = 0
			if let pos = position {
				set(pos.complete)
			}
			stop(finished: (position ?? self.position) == .end)
		}
		
		private func set(_ progress: Double) {
			layer.vdAnimationProgress = progress
//			animation.timeOffset = (progress - 1) * animation.duration
			animation.beginTime = (progress - 1) * animation.duration
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
			stop(finished: flag)
		}
		
		private func stop(finished: Bool) {
			animation.propertyAnimations().forEach {
				guard let kp = $0.keyPath, kp != #keyPath(CALayer.vdAnimationProgress),
							let value = layer.presentation()?.value(forKey: kp) else {
					return
				}
				layer.setValue(value, forKey: kp)
			}
			layer.removeAnimation(forKey: id)
			completions.forEach { $0(finished) }
		}
		
		private static func group(for animation: A) -> CAAnimationGroup {
			let progressAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.vdAnimationProgress))
			progressAnimation.fromValue = 0
			progressAnimation.toValue = 1
			let group = (animation as? CAAnimationGroup) ?? CAAnimationGroup()
			let newAnimations = group === animation ? [progressAnimation] : [progressAnimation, animation]
			group.animations = (group.animations ?? []) + newAnimations
			group.fillMode = .forwards
			group.isRemovedOnCompletion = false
			return group
		}
	}
}

private extension CAAnimation {
	func propertyAnimations() -> [CAPropertyAnimation] {
		if let property = self as? CAPropertyAnimation {
			return [property]
		}
		if let childs = (self as? CAAnimationGroup)?.animations?.map({ $0.propertyAnimations() }).joined() {
			return Array(childs)
		}
		return []
	}
}

extension CALayer {
	@NSManaged var vdAnimationProgress: Double
}
