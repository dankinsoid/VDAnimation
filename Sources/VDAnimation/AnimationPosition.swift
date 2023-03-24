import Foundation

public struct AnimationPosition: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, Equatable {
    
    public var complete: Double
    
    public init(_ complete: Double) {
        self.complete = complete
    }
    
    public var reversed: AnimationPosition {
        AnimationPosition(1 - complete)
    }
    
    public init(floatLiteral value: Double) {
        self.init(value)
    }
    
    public init(integerLiteral value: Int) {
        self.init(Double(value))
    }
    
    public static var start: AnimationPosition { 0 }
    public static var end: AnimationPosition { 1 }
    public static func progress(_ value: Double) -> AnimationPosition {
        AnimationPosition(value)
    }
}

extension Optional where Wrapped == AnimationPosition {
    
    public static var current: AnimationPosition? { nil }
}
