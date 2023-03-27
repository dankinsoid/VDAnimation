import Foundation
import QuartzCore

public struct AnimationPair<F: AnimationProtocol, S: AnimationProtocol>: AnimationProtocol {
    
    private let f: F
    private let s: S
    
    public init(_ f: F, _ s: S) {
        self.f = f
        self.s = s
    }
    
    public func accept(visitor: inout some AnimationVisitor) {
        f.accept(visitor: &visitor)
        s.accept(visitor: &visitor)
    }
}
