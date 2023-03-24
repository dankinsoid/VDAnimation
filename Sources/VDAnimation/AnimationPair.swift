import Foundation
import QuartzCore

public struct AnimationPair<F: AnimationProtocol, S: AnimationProtocol>: AnimationProtocol {
    
    private let f: F
    private let s: S
    
    public init(_ f: F, _ s: S) {
        self.f = f
        self.s = s
    }
    
    public var animator: AnimatorPair<F.Animator, S.Animator> {
        AnimatorPair(f.animator, s.animator)
    }
}

public struct AnimatorPair<F, S> {
    
    private let f: F
    private let s: S
    
    public init(_ f: F, _ s: S) {
        self.f = f
        self.s = s
    }
}

struct AnimationsContext {
    
    var caAnimations: [CAAnimation] = []
    var animations: [InteractiveAnimator] = []
}

protocol AnimationVisitor {
    
    mutating func visit(interval: Double, options: _AnimationOptions)
    
    mutating func visit(caAnimation: CAAnimation)
    
    mutating func visit(animatable: () -> Void, options: _AnimationOptions)
    mutating func visit(interactive: any InteractiveAnimator, options: _AnimationOptions)
}

struct UIAnimationVisitor: AnimationVisitor {
    
    private var caAnimation: CAAnimationGroup?
    
    mutating func visit(interval: Double, options: _AnimationOptions) {
        
    }
    
    mutating func visit(animatable: () -> Void, options: _AnimationOptions) {
    }
    
    mutating func visit(caAnimation: CAAnimation) {
        if let animation = self.caAnimation {
            animation.animations?.append(caAnimation)
        } else {
            self.caAnimation = CAAnimationGroup()
            self.caAnimation?.animations?.append(caAnimation)
        }
    }
    
    mutating func visit(interactive: InteractiveAnimator, options: _AnimationOptions) {
        
    }
}

protocol AnimationComponent {
    
    func accept(visitor: inout some AnimationVisitor, options: _AnimationOptions)
}

extension AnimatorPair: AnimationComponent where F: AnimationComponent, S: AnimationComponent {
    
    func accept(visitor: inout some AnimationVisitor, options: _AnimationOptions) {
        f.accept(visitor: &visitor, options: options)
        s.accept(visitor: &visitor, options: options)
    }
}

struct UIViewComp: AnimationComponent {
    
    let closure: () -> Void
    
    func accept(visitor: inout some AnimationVisitor, options: _AnimationOptions) {
//        visitor.visit(<#T##animation: T##T#>, options: options)
    }
}

struct SeqAnimator<Root: AnimationComponent>: AnimationComponent {
    
    let root: Root
    
    func accept(visitor: some AnimationVisitor, options: _AnimationOptions) {
        root.accept(visitor: Visitor(root: visitor), options: options)
        visitor.visit(self, options: <#T##_AnimationOptions#>)
    }
    
    private struct Visitor<Root: AnimationVisitor>: AnimationVisitor {
        
        let root: Root
        
        private mutating func visit() {
        }
       
        mutating func visit(interval: Double, options: _AnimationOptions) {
            
        }
        
        mutating func visit(animatable: () -> Void, options: _AnimationOptions) {
            
        }
        
        mutating func visit(caAnimation: CAAnimation) {
            CAKeyframeAnimation()?.keyPath
            CABasicAnimation().keyPath
            
            CAAnimationGroup()
        }
    }
}
