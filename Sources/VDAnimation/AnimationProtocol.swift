import Foundation

public protocol AnimationProtocol {
    
    associatedtype Animator
    
    // NB: For Xcode to favor autocompleting `var body: Body` over `var body: Never` we must use a
    //     type alias.
    associatedtype _Body
    
    /// A type representing the body of this animation.
    ///
    /// When you create a custom animation by implementing the `body`, Swift
    /// infers this type from the value returned.
    ///
    /// If you create a custom animation by implementing the `animator`, Swift
    /// infers this type to be `Never`.
    typealias Body = _Body
    
    var animator: Animator { get }
    
//    @AnimationBuilder
    var body: Body { get }
}

extension AnimationProtocol where Body == Never {
    
    /// A non-existent body.
    ///
    /// > Warning: Do not invoke this property directly. It will trigger a fatal error at runtime.
    @_transparent
    public var body: Body {
        fatalError(
      """
      '\(Self.self)' has no body. …
      Do not access an animation's 'body' property directly, as it may not exist
      """
        )
    }
}

extension AnimationProtocol where Body: AnimationProtocol, Body.Animator == Animator {
    
    @inlinable
    public var animator: Body.Animator {
        body.animator
    }
}
