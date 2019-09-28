//
//  SwiftUIAnimatable.swift
//  SuperAnimations
//
//  Created by crypto_user on 27.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import SwiftUI
import UIKit

extension Sequential: Animatable {
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
}

final class SingleAnimation: Animatable, AnimatorProtocol, View {
    var progress: Double = 0.0
    var isRunning: Bool = false
    var state: UIViewAnimatingState = .inactive
    var timing: Animate.Timing = .init(duration: 0.25, curve: .easeInOut)
    var parameters: AnimationParameters = .default
    private lazy var animation: Animation = .easeInOut(duration: timing.duration)
    private let block: () -> ()
    
    init(_ block: @escaping () -> ()) {
        self.block = block
    }
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        EmptyView()
    }
    
    func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        withAnimation(animation) {
            block()
            self.progress = 1
        }
        Timer.scheduledTimer(withTimeInterval: timing.duration, repeats: false) { _ in
            completion(.end)
        }
    }
    
    func pause() {
        
    }
    
    func stop(at position: UIViewAnimatingPosition) {
        
    }
    
    func copy(with parameters: AnimationParameters) -> SingleAnimation {
        return self
    }
}

@dynamicMemberLookup
public struct ViewPropertySetter<R: View, T> {
    private let object: R
    private let keyPath: ReferenceWritableKeyPath<R, T>
    
//    func change(from initialState: T, to value: T) {
//        var difference = value - initialState
//        difference.scale(by: 0.5)
//        let newState = initialState + difference
//    }
//
    func set(_ value: T) -> SingleAnimation {
        let kp = keyPath
        return SingleAnimation {
            self.object[keyPath: kp] = value
        }
    }
    
    fileprivate init(object: R, keyPath: ReferenceWritableKeyPath<R, T>) {
        self.object = object
        self.keyPath = keyPath
    }
    
    public subscript<D>(dynamicMember keyPath: WritableKeyPath<T, D>) -> ViewPropertySetter<R, D> {
        return ViewPropertySetter<R, D>(object: object, keyPath: self.keyPath.appending(path: keyPath))
    }
    
    public subscript<D: Animatable>(dynamicMember keyPath: WritableKeyPath<T, D>) -> D {
        get {
            return object[keyPath: self.keyPath.appending(path: keyPath)]
        }
        nonmutating set {
            var value = object[keyPath: self.keyPath.appending(path: keyPath)]
            value.animatableData.scale(by: 0.5)
        }
    }
}

extension View {
    
    func animate(to progress: Double = 1, _ block: (inout ViewPropertyMaker<Self>) -> ()) {
        var maker = ViewPropertyMaker(object: self)
        block(&maker)
        withAnimation {
            let animator = ViewAnimator(changes: maker.getAnimator(), view: self)
            animator.change(to: progress)
        }
    }
    
    func interactive(_ block: (inout ViewPropertyMaker<Self>) -> ()) -> ViewAnimator<Self> {
        var maker = ViewPropertyMaker(object: self)
        block(&maker)
        return ViewAnimator(changes: maker.getAnimator(), view: self)
    }
}

@dynamicMemberLookup
public struct ViewPropertyMaker<R: View> {
    private let object: R
    var changes: [PartialKeyPath<R>: AnyAnimatable<R>] = [:]
    private var setterCount = 0
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D: Animatable>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> D {
        get {
            return (changes[keyPath]?.initialValue as? D) ?? object[keyPath: keyPath]
        }
        set {
            changes[keyPath] = AnyAnimatable(keyPath: keyPath, initial: object[keyPath: keyPath], newValue: newValue, order: setterCount)
            setterCount += 1
        }
    }
    
    public subscript<D: VectorArithmetic>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> D {
        get {
            return (changes[keyPath]?.initialValue as? D) ?? object[keyPath: keyPath]
        }
        set {
            changes[keyPath] = AnyAnimatable(keyPath: keyPath, initial: object[keyPath: keyPath], newValue: newValue, order: setterCount)
            setterCount += 1
        }
    }
    
    public subscript<D>(dynamicMember keyPath: KeyPath<R, D>) -> D {
        object[keyPath: keyPath]
    }
    
    func getAnimator() -> [ViewAnimator<R>.Animation] {
        changes.sorted(by: { $0.value.sortOrder < $1.value.sortOrder }).map({ $0.value.change })
    }
    
}

struct ViewAnimator<R: View> {
    typealias Animation = (R, Double) -> ()
    var changes: [Animation]
    var view: R
    
    func change(to progress: Double) {
        changes.forEach {
            $0(view, progress)
        }
    }
}

struct AnyAnimatable<T: View> {
    let change: (T, Double) -> ()
    let initialValue: Any
    let sortOrder: Int
    
    init<P: Animatable>(keyPath: ReferenceWritableKeyPath<T, P>, initial: P, newValue: P, order: Int) {
        sortOrder = order
        initialValue = initial
        change = { view, progress in
            let value = initial// view[keyPath: keyPath]
            var difference = newValue.animatableData - value.animatableData
            difference.scale(by: progress)
            view[keyPath: keyPath].animatableData = newValue.animatableData + difference
        }
    }
    
    init<P: VectorArithmetic>(keyPath: ReferenceWritableKeyPath<T, P>, initial: P, newValue: P, order: Int) {
        sortOrder = order
        initialValue = initial
        change = { view, progress in
            let value = initial// view[keyPath: keyPath]
            var difference = newValue - value
            difference.scale(by: progress)
            view[keyPath: keyPath] = value + difference
        }
    }
}

extension View {
    
    public var ca: ViewPropertyMaker<Self> {
        return ViewPropertyMaker(object: self)
    }
    
}

