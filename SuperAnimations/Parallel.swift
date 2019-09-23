//
//  Parallel.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Parallel: AnimatorProtocol {
    public var parameters: AnimationParameters
    public var state: UIViewAnimatingState = .inactive
    public var isRunning: Bool = false
    public var progress: Double = 0
    private var animations: [AnimatorProtocol]
    
    init(_ animations: [AnimatorProtocol], parameters: AnimationParameters = .default) {
        self.animations = animations
        self.parameters = parameters
    }
    
    public convenience init(animations: [AnimatorProtocol]) {
        self.init(animations, parameters: .default)
    }
    
    public convenience init(_ animations: AnimatorProtocol...) {
        self.init(animations)
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> ()) {
        animations()
        self.init()
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        start()
    }
    
    public func pause() {
        animations.forEach { $0.pause() }
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        animations.forEach { $0.stop(at: position) }
    }
    
    public func copy(with parameters: AnimationParameters) -> Parallel {
        return Parallel(animations, parameters: parameters)
    }
    
}
