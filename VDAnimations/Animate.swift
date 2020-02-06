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
    private let animator: Animator
    private var springTiming: UISpringTimingParameters?
    
    public init(_ block: @escaping () -> ()) {
        animator = Animator(block)
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        animator.reset(at: .start)
        guard options.duration?.absolute ?? 0 > 0 else {
            animator.animation()
            completion(true)
            return
        }
        let provider = VDTimingProvider(bezier: options.curve, spring: springTiming)
        let animator = VDViewAnimator(duration: options.duration?.absolute ?? 0, timingParameters: provider)
        animator.addAnimations(self.animator.animation)
        animator.addCompletion { position in
            completion(position == .end)
        }
        animator.startAnimation()
    }
    
    public func canSet(state: AnimationState) -> Bool {
        switch state {
        case .start:            return false
        case .progress, .end:   return true
        }
    }
    
    public func set(state: AnimationState) {
        animator.set(state: state)
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
    private var interactor: VDViewAnimator?
    let animation: () -> ()
    
    init(_ block: @escaping () -> ()) {
        animation = block
    }
    
    deinit {
        reset(at: .end)
    }
    
    func reset(at finalPosition: UIViewAnimatingPosition) {
        interactor?.finishAnimation(at: finalPosition)
        interactor = nil
    }
    
    func set(state: AnimationState) {
        switch state {
        case .start:
            reset(at: .start)
        case .progress(let k):
            create().fractionComplete = CGFloat(k)
        case .end:
            _ = create()
            reset(at: .end)
        }
    }
    
    func create() -> VDViewAnimator {
        if let result = interactor {
            return result
        }
        let result = VDViewAnimator()
        result.addAnimations(animation)
        interactor = result
        return result
    }
    
}
