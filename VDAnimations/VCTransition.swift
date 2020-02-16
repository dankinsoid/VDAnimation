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

public final class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
   
    let presenting: (TransitionContext) -> VDAnimationProtocol
    let dismissing: ((TransitionContext) -> VDAnimationProtocol)?
    
    convenience public init(_ presenting: @escaping (TransitionContext) -> VDAnimationProtocol) {
        self.init(presenting, nil)
    }
    
    public init(_ presenting: @escaping (TransitionContext) -> VDAnimationProtocol, _ dismissing: ((TransitionContext) -> VDAnimationProtocol)?) {
        self.presenting = presenting
        self.dismissing = dismissing
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        AnimatedTransitioning(self.presenting, needReverse: false)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        AnimatedTransitioning(dismissing ?? presenting, needReverse: dismissing == nil)
    }
    
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        nil
    }
    
}

final class AnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let presenting: (TransitionContext) -> VDAnimationProtocol
    private var presentingAnimation: VDAnimationProtocol?
    private let defaultDuration = TimeInterval(UINavigationController.hideShowBarDuration)
    private let needReverse: Bool
    
    init(_ presenting: @escaping (TransitionContext) -> VDAnimationProtocol, needReverse: Bool) {
        self.presenting = presenting
        self.needReverse = needReverse
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let context = transitionContext?.context else { return defaultDuration }
        let animation = presentAnimation(context)
        return animation.options.duration?.absolute ?? defaultDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let context = transitionContext.context else { return }
        let containerView = context.container
        
        print(context.from.subviews.count)
        
        containerView.backgroundColor = .clear
        containerView.addSubview(context.to)
        containerView.clipsToBounds = true
        containerView.sendSubviewToBack(context.to)
        
        let animation = presentAnimation(context)
        
        let duration = animation.options.duration?.absolute ?? defaultDuration
        let options = AnimationOptions.empty.chain
            .duration[.absolute(duration)]
//            .autoreverseStep[needReverse ? .back : nil]
        
        animation.start(with: options) { _ in
            context.from.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func presentAnimation(_ context: TransitionContext) -> VDAnimationProtocol {
        if let anim = presentingAnimation { return anim }
        let animation = presentingAnimation ?? presenting(context)
        presentingAnimation = animation
        return animation
    }
    
//    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
//
//    }
//
//    func animationEnded(_ transitionCompleted: Bool) {
//
//    }
    
}

final class InteractiveTransition: UIPercentDrivenInteractiveTransition, UIViewImplicitlyAnimating {
    
//    var animation: VDAnimationProtocol
    var delegate: AnimationDelegate?
    var state = UIViewAnimatingState.inactive
    var isRunning = false
    var isReversed = false
    var fractionComplete: CGFloat = 0.0 {
        didSet { update(fractionComplete) }
    }
    
    func startAnimation() {
        guard delegate == nil else { return }
//        delegate = animation.start()
    }
    
    func startAnimation(afterDelay delay: TimeInterval) {
        guard delay > 0 else { return startAnimation() }
        DispatchTimer.execute(seconds: delay, startAnimation)
    }
    
    func pauseAnimation() {
        pause()
    }
    
    func stopAnimation(_ withoutFinishing: Bool) {
        delegate?.stop()
    }
    
    func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
        switch finalPosition {
        case .start:
            pause()
            fractionComplete = 0
        case .current:
            pause()
        default:
            break
        }
        finish()
    }
    
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
        guard let fromVC = viewController(forKey: .from),
            let toVC = viewController(forKey: .to) else { return nil }
        return TransitionContext(
            from: fromVC.view,
            to: toVC.view,
            container: containerView,
            finalFrame: finalFrame(for: toVC)
        )
    }
}
