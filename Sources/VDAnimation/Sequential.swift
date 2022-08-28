import Foundation

public struct Sequential: VDAnimationProtocol {
    
	private let animations: [VDAnimationProtocol]
	
	public init(_ animations: [VDAnimationProtocol]) {
		self.animations = animations
	}
	
	public init(_ animations: VDAnimationProtocol...) {
		self = Sequential(animations)
	}
	
	public init(@AnimationsBuilder _ animations: () -> [VDAnimationProtocol]) {
		self = Sequential(animations())
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		if animations.count == 1 {
			return animations[0].delegate(with: options)
		} else if animations.isEmpty {
			return EmptyAnimationDelegate()
		} else {
			return SequentialDelegate(animations: animations.map { $0.delegate(with: .empty) }, options: options)
		}
	}
}
