//
//  SwiftUIAnimate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

///UIKit animation
public struct Animate: AnimationClosureProviderProtocol {
    private let interactor: Interactor
    private let animator = Animator()
    private var springTiming: UISpringTimingParameters?
    
    public init(_ block: @escaping () -> ()) {
        interactor = Interactor(block)
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        switch options.autoreverseStep {
        case .none:
            animator.animator = nil
            return startAnimation(with: options, complete: true, reverse: false, completion)
        case .forward:
            return startAnimation(with: options, complete: false, reverse: false, completion)
        case .back:
            animator.animator?.finishAnimation(at: .start)
            animator.animator = nil
            return startAnimation(with: options, complete: true, reverse: true, completion)
        }
    }
    
    private func startAnimation(with options: AnimationOptions, complete: Bool, reverse: Bool, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        interactor.reset(at: .start)
        guard options.duration?.absolute ?? 0 > 0 || !complete else {
            var end = AnimationState.start
            if !reverse {
                interactor.animation()
                end = .end
            }
            completion(true)
            return AnimationDelegate(stop: { _ in end })
        }
        let provider = VDTimingProvider(bezier: options.curve, spring: springTiming)
        let animator = VDViewAnimator(duration: options.duration?.absolute ?? 0, timingParameters: provider)
        animator.addAnimations(interactor.animation)
        
        let endState: UIViewAnimatingPosition = reverse ? .start : .end
        animator.addCompletion {[interactor] position in
            interactor.position = position
            completion(position == endState)
        }
        animator.pausesOnCompletion = !complete
        if reverse {
            animator.fractionComplete = 1
            animator.isReversed = true
        }
        if !complete {
            self.animator.animator = animator
        }
        animator.startAnimation()
        return AnimationDelegate {
            switch $0 {
            case .start:
                animator.finishAnimation(at: .start)
            case .progress(let k):
                animator.pauseAnimation()
                animator.fractionComplete = CGFloat(k)
                animator.finishAnimation(at: .current)
            case .end:
                animator.finishAnimation(at: .end)
            }
            return $0
        }
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        let state = options.isReversed ? state.reversed : state
        interactor.set(state: state)
    }
    
    public func spring(_ dampingRatio: CGFloat = 0.3) -> Animate {
        chain.springTiming[UISpringTimingParameters(dampingRatio: dampingRatio)]
    }
    
}

@objc(_TtC15SuperAnimationsVDTimingProvider)
fileprivate class VDTimingProvider: NSObject, UITimingCurveProvider {
    let timingCurveType: UITimingCurveType
    let cubicTimingParameters: UICubicTimingParameters?
    let springTimingParameters: UISpringTimingParameters?
    
    init(bezier: BezierCurve?, spring: UISpringTimingParameters?) {
        var isBuiltin = false
        if let bezier = bezier {
            if let builtin = bezier.builtin {
                cubicTimingParameters = UICubicTimingParameters(animationCurve: builtin)
                isBuiltin = true
            } else {
                cubicTimingParameters = UICubicTimingParameters(controlPoint1: bezier.point1, controlPoint2: bezier.point2)
            }
        } else if spring == nil {
            cubicTimingParameters = UICubicTimingParameters(animationCurve: .linear)
            isBuiltin = true
        } else {
            cubicTimingParameters = nil
        }
        springTimingParameters = spring
        switch (bezier, spring) {
        case (.some, .some): timingCurveType = .composed
        case (.some, .none): timingCurveType = isBuiltin ? .builtin : .cubic
        case (.none, .some): timingCurveType = .spring
        case (.none, .none): timingCurveType = .cubic
        }
    }
    
    init(timing: UITimingCurveType, cubic: UICubicTimingParameters?, spring: UISpringTimingParameters?) {
        self.timingCurveType = timing
        self.cubicTimingParameters = cubic
        self.springTimingParameters = spring
    }
    
    required init?(coder: NSCoder) {
        timingCurveType = UITimingCurveType(rawValue: coder.decodeInteger(forKey: Keys.timingCurveType)) ?? .cubic
        cubicTimingParameters = coder.decodeObject(of: UICubicTimingParameters.self, forKey: Keys.cubicTimingParameters)
        springTimingParameters = coder.decodeObject(of: UISpringTimingParameters.self, forKey: Keys.springTimingParameters)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(timingCurveType.rawValue, forKey: Keys.timingCurveType)
        coder.encode(cubicTimingParameters, forKey: Keys.cubicTimingParameters)
        coder.encode(springTimingParameters, forKey: Keys.springTimingParameters)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return VDTimingProvider(timing: timingCurveType, cubic: cubicTimingParameters, spring: springTimingParameters)
    }
    
    fileprivate struct Keys {
        static let timingCurveType = "timingCurveType"
        static let cubicTimingParameters = "cubicTimingParameters"
        static let springTimingParameters = "springTimingParameters"
    }
    
}

fileprivate final class Animator {
    var animator: VDViewAnimator?
}

fileprivate final class Interactor {
    private var animator: VDViewAnimator?
    let animation: () -> ()
    var position = UIViewAnimatingPosition.start
    
    init(_ block: @escaping () -> ()) {
        animation = block
    }
    
    deinit {
        reset(at: .end)
    }
    
    func reset(at finalPosition: UIViewAnimatingPosition) {
        animator?.finishAnimation(at: finalPosition)
        animator = nil
        position = finalPosition
    }
    
    func set(state: AnimationState) {
        switch state {
        case .start:
            guard position != .start else { return }
            reset(at: .start)
        case .progress(let k):
            create().fractionComplete = CGFloat(k)
        case .end:
            guard position != .end else { return }
            _ = create()
            reset(at: .end)
        }
    }
    
    func create() -> VDViewAnimator {
        if let result = animator {
            return result
        }
        let result = VDViewAnimator()
        result.addAnimations(animation)
        animator = result
        return result
    }
    
}
