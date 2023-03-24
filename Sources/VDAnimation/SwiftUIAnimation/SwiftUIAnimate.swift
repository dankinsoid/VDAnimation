import SwiftUI

public struct SwiftUIAnimate: AnimationProtocol {
    
    private let animation: () -> Void
    
    public init(_ animation: @escaping () -> Void) {
        self.animation = animation
    }
    
    public var animator: SwiftUIAnimator {
        SwiftUIAnimator(animation)
    }
}

public struct SwiftUIAnimator: PlayableAnimator {
    
    private let animation: () -> Void
    
    public init(_ animation: @escaping () -> Void) {
        self.animation = animation
    }
    
    public func play(with options: _AnimationOptions) {
        withAnimation(options.swiftUIAnimation, animation)
    }
}

public extension _AnimationOptions {
    
    var swiftUIAnimation: Animation {
        get { self[\.swiftUIAnimation] ?? .default }
        set { self[\.swiftUIAnimation] = newValue }
    }
}
