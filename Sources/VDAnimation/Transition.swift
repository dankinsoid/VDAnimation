//
//  Transition.swift
//  CA
//
//  Created by Daniil on 01.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct Transition: VDAnimationProtocol {
    private let from: UIView
    private let to: UIView
    
    public init(from: UIView, to: UIView) {
        self.from = from
        self.to = to
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
        let (v1, v2) = options.isReversed ? (to, from) : (from, to)
        UIView.transition(
            from: v1,
            to: v2,
            duration: options.duration?.absolute ?? 0,
            options: [.showHideTransitionViews],
            completion: completion
        )
        return .end
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {}

}
