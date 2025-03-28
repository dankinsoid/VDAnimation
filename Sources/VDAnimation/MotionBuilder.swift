import Foundation

/// A result builder for creating motion animations
///
/// This result builder allows for a declarative syntax when creating complex animations.
/// It transforms Swift's DSL syntax into motion objects that can be composed together.
///
/// Example:
/// ```swift
/// // Using MotionBuilder with a function
/// func createAnimation() -> AnyMotion<CGFloat> {
///     MotionBuilder<CGFloat>.buildBlock(
///         To(1.0).duration(0.5),
///         Wait(Duration.absolute(0.2)),
///         To(0.0).duration(0.5)
///     )
/// }
///
/// // With result builder syntax
/// @MotionBuilder<CGFloat>
/// func createBetterAnimation() -> AnyMotion<CGFloat> {
///     To(1.0).duration(0.5)
///     Wait(Duration.absolute(0.2))
///     To(0.0).duration(0.5)
/// }
/// ```
@resultBuilder
public struct MotionBuilder<Value> {
    /// Builds a single expression into a motion
    public static func buildExpression<M: Motion>(_ expression: M) -> AnyMotion<Value> where M.Value == Value {
        expression.anyMotion
    }
    
    /// Builds an optional expression
    public static func buildOptional(_ component: AnyMotion<Value>?) -> AnyMotion<Value> {
        // ... implementation ...
    }
    
    /// Builds a block of expressions
    public static func buildBlock(_ components: AnyMotion<Value>...) -> AnyMotion<Value> {
        // ... implementation ...
    }
    
    /// Combines all components into a final motion
    public static func buildFinalResult(_ component: AnyMotion<Value>) -> AnyMotion<Value> {
        component
    }
}

/// A result builder for creating arrays of motions
///
/// This result builder is used by `Sequential` to create an array of motions
/// to be played in sequence.
///
/// Example:
/// ```swift
/// // Creating a sequence directly
/// let animations: [AnyMotion<CGFloat>] = MotionsArrayBuilder<CGFloat>.buildBlock(
///     To(1.0).duration(0.3),
///     To(0.5).duration(0.2),
///     To(0.0).duration(0.3)
/// )
///
/// // More commonly used with Sequential
/// let sequence = Sequential<CGFloat> {
///     To(1.0).duration(0.3)
///     To(0.5).duration(0.2)
///     To(0.0).duration(0.3)
/// }
/// ```
@resultBuilder
public struct MotionsArrayBuilder<Value> {
    /// Builds an empty array
    public static func buildBlock() -> [AnyMotion<Value>] {
        []
    }
    
    /// Builds a single motion into an array
    public static func buildExpression<M: Motion>(_ expression: M) -> [AnyMotion<Value>] where M.Value == Value {
        [expression.anyMotion]
    }
    
    /// Builds a block of motions
    public static func buildBlock(_ components: [AnyMotion<Value>]...) -> [AnyMotion<Value>] {
        components.flatMap { $0 }
    }
    
    /// Combines all components into a final array
    public static func buildFinalResult(_ component: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        component
    }
}
