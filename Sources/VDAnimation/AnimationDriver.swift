import Foundation

@MainActor
public protocol AnimationDriver {
    
    var progress: Double { get nonmutating set }
    var isAnimating: Bool { get nonmutating set }
    func play(
        from: Double?,
        to progress: Double?,
        repeat repeatForever: Bool,
        completion: (() -> Void)?
    )
    func reverse(from: Double?)
    func toggle()
    func pause()
    func stop(at progress: Double)
}

extension AnimationDriver {

    public func reverse() {
        reverse(from: nil)
    }

    public func stop() {
        stop(at: 0)
    }

    public func play() {
        play(from: nil, to: nil, repeat: false, completion: nil)
    }
}
