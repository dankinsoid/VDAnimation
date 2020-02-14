//
//  VCTransition.swift
//  CA
//
//  Created by crypto_user on 14.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public protocol TransatableController: UIViewController {}

extension UIViewController: TransatableController {
    
    public func present(_ viewController: UIViewController, completion: (() -> ())? = nil, _ animation: @escaping (TransitionContext) -> VDAnimationProtocol) {
        var delegate: TransitionDelegate? = TransitionDelegate(animation)
        viewController.modalPresentationStyle = .fullScreen
        viewController.transitioningDelegate = delegate
        present(viewController, animated: true) {
            completion?()
            delegate = nil
        }
    }
    
}

extension TransatableController {
    public func present<VC>(_ viewController: VC, animation: (Self, VC) -> ()) {}
}

final class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
   
    let presenting: (TransitionContext) -> VDAnimationProtocol
    
    init(_ presenting: @escaping (TransitionContext) -> VDAnimationProtocol) {
        self.presenting = presenting
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        AnimatedTransitioning(self.presenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        nil
    }
    
}

final class AnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let presenting: (TransitionContext) -> VDAnimationProtocol
    let defaultDuration = Double(UINavigationController.hideShowBarDuration)
    
    init(_ presenting: @escaping (TransitionContext) -> VDAnimationProtocol) {
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let context = transitionContext?.context else { return defaultDuration }
        let animation = presenting(context)
        return animation.options.duration?.absolute ?? defaultDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let context = transitionContext.context else { return }
        let containerView = context.container
        
        containerView.backgroundColor = .clear
        containerView.addSubview(context.to)
        containerView.clipsToBounds = true
        containerView.sendSubviewToBack(context.to)
//        let snapshot = toVC.view.snapshotView(afterScreenUpdates: true)!
        
        let animation = presenting(context)
        
        let duration = animation.options.duration?.absolute ?? defaultDuration
        let options = AnimationOptions.empty.chain.duration[.absolute(duration)]
        
        animation.start(with: options) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
//    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
//
//    }
//
//    func animationEnded(_ transitionCompleted: Bool) {
//
//    }
    
}

final class InteractiveTransition: UIPercentDrivenInteractiveTransition {
}

//final class ImplicitlyAnimating: NSObject, UIViewImplicitlyAnimating {
//    let animation: VDAnimationProtocol
//    var delegate: AnimationDelegate?
//    var state: UIViewAnimatingState
//    var isRunning: Bool
//    var isReversed: Bool
//    var fractionComplete: CGFloat
//
//    func startAnimation() {
//        delegate = animation.start()
//    }
//
//    func startAnimation(afterDelay delay: TimeInterval) {
//        delegate = animation.delay(delay).start()
//    }
//
//    func pauseAnimation() {
//        delegate?.stop()
//    }
//
//    func stopAnimation(_ withoutFinishing: Bool) {
//        delegate?.stop()
//    }
//
//    func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
//        delegate?.stop(<#T##position: AnimationPosition##AnimationPosition#>)
//    }
//
//
//}

public struct TransitionContext {
    public let from: UIView
    public let to: UIView
    public let container: UIView
    public let finalFrame: CGRect
}

extension UIViewControllerContextTransitioning {
    var context: TransitionContext? {
        guard let fromVC = viewController(forKey: .from), let toVC = viewController(forKey: .to) else { return nil }
        return TransitionContext(from: fromVC.view, to: toVC.view, container: containerView, finalFrame: finalFrame(for: toVC))
    }
}
