import Foundation

public protocol PlayableAnimator {
    
    mutating func play(with options: _AnimationOptions, completion: @escaping (Bool) -> Void)
    func expected(options: inout _AnimationOptions)
}

public extension PlayableAnimator {
    
    func expected(options: inout _AnimationOptions) {
    }
}

extension PlayableAnimator {
    
    public mutating func play(with options: _AnimationOptions) {
        play(with: options, completion: { _ in })
    }
}

public protocol InteractiveAnimator: PlayableAnimator {
    
    var isPlaying: Bool { get }
    var position: AnimationPosition { get set }
    mutating func pause()
    mutating func stop()
}
