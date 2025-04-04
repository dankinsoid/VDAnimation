import SwiftUI

/// A struct representing a bidirectional range.
public struct Tween<Bound>: CustomStringConvertible {

    /// The starting value of the tween (when t=0)
    public var start: Bound

    /// The ending value of the tween (when t=1)
    public var end: Bound

    public var description: String {
        "(\(start) -> \(end))"
    }

    /// Creates a new tween between two values
    /// - Parameters:
    ///   - start: The starting value
    ///   - end: The ending value
    public init(_ start: Bound, _ end: Bound) {
        self.start = start
        self.end = end
    }

    public var reversed: Tween {
        Tween(end, start)
    }

    public func map<T>(_ transform: (Bound) -> T) -> Tween<T> {
        Tween<T>(transform(start), transform(end))
    }
}

extension Tween: Tweenable where Bound: Tweenable {

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

extension Tween: RangeExpression where Bound: Comparable {

    public init(_ range: Range<Bound>) {
        self.init(range.lowerBound, range.upperBound)
    }

    public init(_ range: ClosedRange<Bound>) {
        self.init(range.lowerBound, range.upperBound)
    }

    public var range: Range<Bound> {
        min(start, end)..<max(start, end)
    }

    public var closedRange: ClosedRange<Bound> {
        min(start, end)...max(start, end)
    }

    public func relative<C>(to collection: C) -> Range<Bound> where C : Collection, Bound == C.Index {
        closedRange.relative(to: collection)
    }

    public func contains(_ element: Bound) -> Bool {
        closedRange.contains(element)
    }
}

extension Tween: AdditiveArithmetic where Bound: AdditiveArithmetic {

    public static var zero: Tween<Bound> {
        Tween(.zero, .zero)
    }

    public var difference: Bound {
        end - start
    }

    public static func +(_ lhs: Tween, _ rhs: Tween) -> Tween {
        Tween(lhs.start + rhs.start, lhs.end + rhs.end)
    }

    public static func -(lhs: Tween<Bound>, rhs: Tween<Bound>) -> Tween<Bound> {
        Tween(lhs.start - rhs.start, lhs.end - rhs.end)
    }
}

extension Tween: VectorArithmetic where Bound: VectorArithmetic {

    public mutating func scale(by rhs: Double) {
        start.scale(by: rhs)
        end.scale(by: rhs)
    }

    public var magnitudeSquared: Double {
        AnimatablePair(start, end).magnitudeSquared
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
