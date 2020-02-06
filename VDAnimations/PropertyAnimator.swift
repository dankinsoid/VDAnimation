//
//  PropertyAnimator.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

final class PropertyAnimator<T, A: AnimationClosureProviderProtocol>: AnimationProviderProtocol {
    private var initial: T?
    private let value: T
    private let scale: (T, Double, T) -> T
    private let setter: (T?) -> ()
    private let getter: () -> T?
        
    init(from initial: T?, getter: @escaping () -> T?, setter: @escaping (T?) -> (), scale: @escaping (T, Double, T) -> T, value: T, animatorType: A.Type) {
        self.scale = scale
        self.setter = setter
        self.initial = initial
        self.getter = getter
        self.value = value
    }
    
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        setter(initial)
        initial = initial ?? getter()
        A.init({ self.setter(self.value) }).start(with: options, completion)
    }
    
    func canSet(state: AnimationState) -> Bool { true }
    
    func set(state: AnimationState) {
        if initial == nil { initial = getter() }
        switch state {
        case .start:
            setter(initial)
        case .progress(let k):
            setter(scale(initial ?? value, k, value))
        case .end:
            setter(value)
        }
    }
    
}
