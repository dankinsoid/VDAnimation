//
//  PropertyAnimator.swift
//  CA
//
//  Created by Daniil on 17.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

@dynamicMemberLookup
public struct PropertyAnimator<Base, A: ClosureAnimation>: VDAnimationProtocol {
    let animatable: PropertyAnimatable
    private let get: () -> Base?
        
    init(_ animatable: PropertyAnimatable, get: @escaping () -> Base?) {
        self.animatable = animatable
        self.get = get
    }
        
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        animatable.updateInitial()
        var option = options
        option.autoreverseStep = nil
        if options.isReversed {
            animatable.setState(.end)
            return A.init({ self.animatable.setState(.start) }).start(with: option, completion)
        } else {
            animatable.setState(.start)
            return A.init({ self.animatable.setState(.end) }).start(with: option, completion)
        }
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        animatable.setState(options.isReversed == true ? position.reversed : position)
    }
    
    public subscript<A>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, A>) -> AnimatePropertyMapper<Base, A> {
        AnimatePropertyMapper(object: get, animatable: animatable, keyPath: keyPath)
    }
    
}

final class PropertyAnimatable {
    var updateInitial: () -> ()
    var setState: (AnimationPosition) -> ()
    
    static let empty = PropertyAnimatable(update: {}, set: {_ in})
    
    init(update: @escaping () -> (), set: @escaping (AnimationPosition) -> ()) {
        updateInitial = update
        setState = set
    }
    
    func union(_ other: PropertyAnimatable) -> PropertyAnimatable {
        PropertyAnimatable(
            update: {
                self.updateInitial()
                other.updateInitial()
            },
            set: {
                self.setState($0)
                other.setState($0)
            }
        )
    }
    
}


final class PropertyOwner<T> {
    private var initial: T?
    private let value: T
    private let scale: (T, Double, T) -> T
    private let setter: (T?) -> ()
    private let getter: () -> T?
    
    var asAnimatable: PropertyAnimatable {
        PropertyAnimatable(update: updateInitial, set: set)
    }
    
    init(from initial: T?, getter: @escaping () -> T?, setter: @escaping (T?) -> (), scale: @escaping (T, Double, T) -> T, value: T) {
        self.scale = scale
        self.setter = setter
        self.initial = initial
        self.getter = getter
        self.value = value
    }
    
    func updateInitial() {
        if initial == nil { initial = getter() }
    }
    
    func set(position: AnimationPosition) {
        switch position {
        case .start:
            setter(initial)
        case .progress(let k):
            updateInitial()
            setter(scale(initial ?? value, k, value))
        case .end:
            setter(value)
        }
    }
    
}
