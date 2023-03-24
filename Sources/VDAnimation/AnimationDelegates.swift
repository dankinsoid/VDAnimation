import UIKit

public protocol PrimitiveAnimationDelegate {
    
    associatedtype Options
    associatedtype Result = Void
    func start(with options: Options) -> Result
}

public protocol AnimationWithCompletionDelegate: PrimitiveAnimationDelegate {
    
    func start(with options: Options, _ completion: @escaping (Bool) -> Void) -> Result
}

extension PrimitiveAnimationDelegate where Self: AnimationWithCompletionDelegate {
    
    public func start(with options: Options) -> Result {
        start(with: options) { _ in }
    }
}

public protocol InterruptableAnimationDelegate: AnimationWithCompletionDelegate {
   
    var isRunning: Bool { get nonmutating set }
    func stop(at position: UIViewAnimatingPosition)
}

public protocol InteractiveAnimationDelegate: InterruptableAnimationDelegate {
    
    var position: AnimationPosition { get nonmutating set }
}

public protocol PrimitiveAnimationType {
    
    associatedtype Delegate: PrimitiveAnimationDelegate
    typealias Options = Delegate.Options
    func createDelegate() -> Delegate
    func createOptions() -> Options
}

public protocol AnimationType: PrimitiveAnimationType {
    
    var flatten: [AnimationCast] { get }
}

extension AnimationType {
    
    public var flatten: [AnimationCast] {
        [
            AnimationCast { proposal in
                proposal.min ?? proposal.max ?? .relative(1)
            }
        ]
    }
}

public struct AnimationCast {
    
    private var _duration: (ProposedAnimationDuration) -> AnimationDuration
    
    public init(_ duration: @escaping (ProposedAnimationDuration) -> AnimationDuration) {
        _duration = duration
    }
    
    public func duration(proposal: ProposedAnimationDuration) -> AnimationDuration {
        _duration(proposal)
    }
}
