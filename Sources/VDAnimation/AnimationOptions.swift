import Foundation

public struct AnimationOptions: Equatable, ExpressibleByArrayLiteral {
    
	public typealias ArrayLiteralElement = AnimationOptions
	
	public static var empty: AnimationOptions { AnimationOptions() }
	public static func duration(_ duration: AnimationDuration?) -> AnimationOptions { .init(duration: duration) }
	public static func curve(_ curve: BezierCurve?) -> AnimationOptions { .init(curve: curve) }
	public static func complete(_ complete: Bool?) -> AnimationOptions { .init(complete: complete) }
	public static func isReversed(_ isReversed: Bool?) -> AnimationOptions { .init(isReversed: isReversed) }
	
	public var duration: AnimationDuration?
	public var curve: BezierCurve?
	public var complete: Bool?
	public var isReversed: Bool?
	
	public init(arrayLiteral elements: AnimationOptions...) {
		if elements.isEmpty {
			self = .init()
		} else {
			self = elements.dropFirst().reduce(elements[0]) { $0.or($1) }
		}
	}
	
	public init(
		duration: AnimationDuration? = nil,
		curve: BezierCurve? = nil,
	  complete: Bool? = nil,
	 	isReversed: Bool? = nil
	) {
		self.duration = duration
		self.curve = curve
		self.complete = complete
		self.isReversed = isReversed
	}
	
	public init() {}
	
	public func or(_ other: AnimationOptions) -> AnimationOptions {
		AnimationOptions(
			duration: duration ?? other.duration,
			curve: curve ?? other.curve,
			complete: complete ?? other.complete,
			isReversed: isReversed ?? other.isReversed
		)
	}
	
	public func set(_ other: AnimationOptions) -> AnimationOptions {
		other.or(self)
	}
}
