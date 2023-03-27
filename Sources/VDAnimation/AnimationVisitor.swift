import Foundation

public protocol AnimationVisitor {
    
    mutating func visit(interactive: some InteractiveAnimator)
}
