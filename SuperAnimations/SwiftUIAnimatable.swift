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

final class SingleAnimation: Animatable, AnimatorProtocol {
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
    
}

@dynamicMemberLookup
public struct ViewPropertyMaker<R: View> {
    private let object: R
    
    fileprivate init(object: R) {
        self.object = object
    }
    
    public subscript<D>(dynamicMember keyPath: ReferenceWritableKeyPath<R, D>) -> ViewPropertySetter<R, D> {
        return ViewPropertySetter<R, D>(object: object, keyPath: keyPath)
    }
    
}

extension View {
    
    public var ca: ViewPropertyMaker<Self> {
        return ViewPropertyMaker(object: self)
    }
    
}
