import Foundation

struct SequentialAnimator: InteractiveAnimator {
    
    var isPlaying: Bool = false
    var position: AnimationPosition = .start
    var animators: [any InteractiveAnimator]
    
    init(animators: [any InteractiveAnimator]) {
        self.animators = animators
    }
    
    mutating func play(with options: _AnimationOptions, completion: @escaping (Bool) -> Void) {
        
    }
    
    func expected(options: inout _AnimationOptions) {
        
    }
    
    mutating func pause() {
        
    }
    
    mutating func stop() {
        
    }
}


private func fullDuration(for array: [any InteractiveAnimator]) -> AnimationDuration? {
    guard array.contains(where: {
        $0.options.duration?.absolute != nil && !$0.isInstant
    }) else { return nil }
    let dur = array.reduce(0, { $0 + ($1.options.duration?.absolute ?? 0) })
    var rel = min(1, array.reduce(0, { $0 + ($1.options.duration?.relative ?? 0) }))
    if rel == 0 {
        rel = Double(array.filter({ $0.options.duration == nil }).count) / Double(array.count)
    }
    rel = rel == 1 ? 0 : rel
    let full = dur / (1 - rel)
    return .absolute(full)
}
