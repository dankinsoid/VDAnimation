//
//  Animate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

///UIKit animation
public struct UIViewAnimate: AnimationProviderProtocol {
    private let animation: () -> ()
    private let prepare: () -> ()
    private var springTiming: UISpringTimingParameters?
    
    public init(_ block: @escaping () -> ()) {
        animation = block
        prepare = {}
    }
    
    init(_ block: @escaping () -> (), before: @escaping () -> ()) {
        animation = block
        prepare = before
    }
    
    public func start(with options: AnimationOptions?, _ completion: @escaping (Bool) -> ()) {
        let provider = VDTimingProvider(bezier: options?.curve, spring: springTiming)
        let animator = VDViewAnimator(duration: options?.duration?.absolute ?? 0, timingParameters: provider)
        animator.addAnimations(animation)
//        animator.reverseOnComplete = false
//        animator.isReversed = true
//        animator.fractionComplete = 0
        animator.startAnimation { position in
            completion(position == .end)
        }
    }
    
    public func spring(_ dampingRatio: CGFloat = 0.3) -> UIViewAnimate {
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

