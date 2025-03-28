import Foundation

/// A struct representing an interpolation between two values of the same type
///
/// Tween encapsulates start and end values of a type that conforms to `Tweenable`,
/// providing a convenient way to perform interpolation between those values.
public struct Tween<Bound: Tweenable>: Tweenable {

    /// The starting value of the tween (when t=0)
    public var start: Bound
    
    /// The ending value of the tween (when t=1)
    public var end: Bound

    /// Creates a new tween between two values
    /// - Parameters:
    ///   - start: The starting value
    ///   - end: The ending value
    public init(_ start: Bound, _ end: Bound) {
        self.start = start
        self.end = end
    }

    /// Interpolates between the start and end values
    /// - Parameter t: The interpolation factor (typically between 0 and 1)
    /// - Returns: The interpolated value
    public func lerp(_ t: Double) -> Bound {
        Bound.lerp(start, end, t)
    }

    /// Linearly interpolates between two tweens
    /// - Parameters:
    ///   - lhs: Starting tween when t=0
    ///   - rhs: Ending tween when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: A new tween with interpolated start and end values
    public static func lerp(_ lhs: Tween<Bound>, _ rhs: Tween<Bound>, _ t: Double) -> Tween<Bound> {
        Tween(.lerp(lhs.start, rhs.start, t), .lerp(lhs.end, rhs.end, t))
    }
}

/// Conformance to Sendable protocol when the bounded type is Sendable
extension Tween: Sendable where Bound: Sendable {}

/// Conformance to Equatable protocol when the bounded type is Equatable
extension Tween: Equatable where Bound: Equatable {}

/// Conformance to Hashable protocol when the bounded type is Hashable
extension Tween: Hashable where Bound: Hashable {}

/// Conformance to Encodable protocol when the bounded type is Encodable
extension Tween: Encodable where Bound: Encodable {}

/// Conformance to Decodable protocol when the bounded type is Decodable
extension Tween: Decodable where Bound: Decodable {}
