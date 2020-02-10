//
//  Transition.swift
//  CA
//
//  Created by Daniil on 01.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct Transition: AnimationProviderProtocol {
    private let from: UIView
    private let to: UIView
    
    public init(from: UIView, to: UIView) {
        self.from = from
        self.to = to
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        let (v1, v2) = options.isReversed ? (to, from) : (from, to)
        UIView.transition(
            from: v1,
            to: v2,
            duration: options.duration?.absolute ?? 0,
            options: [.transitionCurlDown, .showHideTransitionViews],
            completion: completion
        )
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {}

}
