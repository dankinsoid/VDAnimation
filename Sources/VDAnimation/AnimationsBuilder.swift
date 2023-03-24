import UIKit

@resultBuilder
public enum AnimationsBuilder {
	
	@inlinable
	public static func buildBlock(_ components: [VDAnimationProtocol]...) -> [VDAnimationProtocol] {
		Array(components.joined())
	}
	
	@inlinable
	public static func buildArray(_ components: [[VDAnimationProtocol]]) -> [VDAnimationProtocol] {
		Array(components.joined())
	}
	
	@inlinable
	public static func buildEither(first component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildEither(second component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildOptional(_ component: [VDAnimationProtocol]?) -> [VDAnimationProtocol] {
		component ?? []
	}
	
	@inlinable
	public static func buildLimitedAvailability(_ component: [VDAnimationProtocol]) -> [VDAnimationProtocol] {
		component
	}
	
	@inlinable
	public static func buildExpression(_ expression: VDAnimationProtocol) -> [VDAnimationProtocol] {
		[expression]
	}
}
