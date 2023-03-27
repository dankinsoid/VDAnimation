import Foundation

public struct Sequential<Base: AnimationProtocol>: AnimationProtocol {
    
	private let base: Base
	
	public init(_ base: Base) {
		self.base = base
	}
	
	public init(@AnimationsBuilder _ base: () -> Base) {
		self = Sequential(base())
	}
    
    public func accept(visitor: inout some AnimationVisitor) {
        var seqVisitor = Visitor(root: visitor)
        base.accept(visitor: &seqVisitor)
        seqVisitor.finish()
    }
    
    private struct Visitor<T: AnimationVisitor>: AnimationVisitor {
        
        var root: T
        var animations: [any InteractiveAnimator] = []
        
        mutating func visit(interactive: some InteractiveAnimator) {
            animations.append(interactive)
        }
        
        mutating func finish() {
            switch animations.count {
            case 0:
                break
            case 1:
                root.visit(interactive: animations[0])
            default:
                root.visit(interactive: SequentialAnimator(animators: animations))
            }
        }
    }
}
