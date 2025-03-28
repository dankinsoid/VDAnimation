import Foundation

@attached(member, conformances: Tweenable, names: arbitrary)
@attached(extension, conformances: Tweenable, names: arbitrary)
public macro Tweenable() = #externalMacro(
    module: "VDAnimationMacros",
    type: "TweenableMacro"
)

public func _lerp<T: Tweenable>(_ lhs: T, _ rhs: T, _ t: Double) -> T {
    T.lerp(lhs, rhs, t)
}

public func _lerp<T: Codable>(_ lhs: T, _ rhs: T, _ t: Double) -> T {
    T.lerp(lhs, rhs, t)
}

public func _lerp<T: Codable & Tweenable>(_ lhs: T, _ rhs: T, _ t: Double) -> T {
    T.lerp(lhs, rhs, t)
}

@_disfavoredOverload
public func _lerp<T>(_ lhs: T, _ rhs: T, _ t: Double) -> T {
    t < 0.5 ? lhs : rhs
}
