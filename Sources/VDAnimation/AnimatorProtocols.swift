import Foundation

public protocol PlayableAnimator {
    
    func play(with options: _AnimationOptions)
    func expected(options: inout _AnimationOptions)
}

public extension PlayableAnimator {
    
    func expected(options: inout _AnimationOptions) {
    }
}

public protocol CompletableAnimator: PlayableAnimator {
    
    func play(with options: _AnimationOptions, completion: @escaping (Bool) -> Void)
}

extension PlayableAnimator where Self: CompletableAnimator {
    
    public func play(with options: _AnimationOptions) {
        play(with: options, completion: { _ in })
    }
}

public protocol PausableAnimator: CompletableAnimator {
    
    var isPlaying: Bool { get }
    func pause()
    func stop()
}

public protocol InteractiveAnimator: PausableAnimator {
    
    var position: AnimationPosition { get nonmutating set }
}
