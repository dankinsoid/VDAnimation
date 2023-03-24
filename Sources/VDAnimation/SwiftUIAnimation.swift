import SwiftUI

public struct SwiftUIAnimation<Result>: PrimitiveAnimationType {
    
    public let options: Animation
    public let body: () -> Result
    
    public init(_ options: Animation = .default, _ body: @escaping () -> Result) {
        self.body = body
        self.options = options
    }
    
    public func createDelegate() -> Delegate {
        Delegate(body: body)
    }
    
    public func createOptions() -> Animation {
        options
    }
    
    public struct Delegate: PrimitiveAnimationDelegate {
        
        let body: () -> Result
        
        public func start(with options: Animation) -> Result {
            withAnimation(options, body)
        }
    }
}
