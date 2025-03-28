import Foundation

public struct Tween<Bound: Tweenable>: Tweenable {

    public var start: Bound
    public var end: Bound

    public init(_ start: Bound, _ end: Bound) {
        self.start = start
        self.end = end
    }

    public func lerp(_ t: Double) -> Bound {
        Bound.lerp(start, end, t)
    }

    public static func lerp(_ lhs: Tween<Bound>, _ rhs: Tween<Bound>, _ t: Double) -> Tween<Bound> {
        Tween(.lerp(lhs.start, rhs.start, t), .lerp(lhs.end, rhs.end, t))
    }
}

extension Tween: Sendable where Bound: Sendable {}
extension Tween: Equatable where Bound: Equatable {}
extension Tween: Hashable where Bound: Hashable {}
extension Tween: Encodable where Bound: Encodable {}
extension Tween: Decodable where Bound: Decodable {}
