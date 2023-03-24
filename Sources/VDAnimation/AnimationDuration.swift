import Foundation

public struct ProposedAnimationDuration {
    
    public var min: AnimationDuration?
    public var max: AnimationDuration?
    
    public init(min: AnimationDuration?, max: AnimationDuration?) {
        self.min = min
        self.max = max
    }
    
    public static var unknown: ProposedAnimationDuration {
        ProposedAnimationDuration(min: nil, max: nil)
    }
    
    public static func fixed(_ value: AnimationDuration) -> ProposedAnimationDuration {
        ProposedAnimationDuration(min: value, max: value)
    }
}
