import Foundation

public struct Timelines: VDAnimationProtocol {
    
	let animations: [ClosedRange<Double>: VDAnimationProtocol]
	let type: AnimationDurationType
	
	public init(_ type: AnimationDurationType, _ animations: [ClosedRange<Double>: VDAnimationProtocol]) {
		self.animations = animations
		self.type = type
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		let maxValue = animations.reduce(0.0) {
			max(max($0, $1.key.lowerBound), $1.key.upperBound)
		}
		return Parallel(
			animations.map { args in
				Sequential {
					if args.key.lowerBound > 0 {
						type == .absolute ? Interval(args.key.lowerBound) : Interval(relative: args.key.lowerBound)
					}
					if type == .absolute {
						args.value.duration(args.key.upperBound - args.key.lowerBound)
					} else {
						args.value.duration(relative: args.key.upperBound - args.key.lowerBound)
					}
					if args.key.upperBound < maxValue {
						type == .absolute ? Interval(maxValue - args.key.upperBound) : Interval(relative: maxValue - args.key.upperBound)
					}
				}
			}
		).delegate(with: options)
	}
}

public enum DurationRange: Hashable {
    
	case absolute(ClosedRange<Double>), relative(ClosedRange<Double>)
}

public enum AnimationDurationType: Hashable {
    
	case absolute, relative
}
