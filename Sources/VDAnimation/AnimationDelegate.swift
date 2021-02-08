//
//  AnimationDelegate.swift
//  CA
//
//  Created by Daniil on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct AnimationDelegate {
    public static var empty: AnimationDelegate { AnimationDelegate({ $0 }) }
    public static var end: AnimationDelegate { AnimationDelegate({_ in .end }) }
    
    private var stopAction: (AnimationPosition) -> AnimationPosition
    
    public init(_ action: @escaping (AnimationPosition) -> AnimationPosition) {
        stopAction = action
    }
    
    @discardableResult
    public func stop(_ position: AnimationPosition = .end) -> AnimationPosition {
        stopAction(position)
    }

}

final class RemoteDelegate {
    var position: AnimationPosition?
    var completion: ((Bool) -> Void)?
    var isStopped: Bool { position != nil }
    
    init(_ completion: ((Bool) -> Void)? = nil) {
        self.completion = completion
    }
    
    var delegate: AnimationDelegate {
        AnimationDelegate {
            self.position = $0
            self.completion?($0.complete == 1)
            return $0
        }
    }
    
}

final class MutableDelegate {
    var delegate = AnimationDelegate.empty
    var asDelegate: AnimationDelegate { AnimationDelegate { self.delegate.stop($0) } }
}

public protocol Interactive {
    var percent: Double { get nonmutating set }
    func play()
    func cancel()
    func pause()
    @discardableResult
    func stop(_ position: AnimationPosition) -> AnimationPosition
}

struct Interact: Interactive {
    static let empty = Interact(getter: { 0 }, setter: {_ in }, player: {}, pause: {}, cancellable: {})
    static let end = Interact(getter: { 1 }, setter: {_ in }, player: {}, pause: {}, cancellable: {})
    
    var percent: Double {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
    private let getter: () -> Double
    private let setter: (Double) -> Void
    private let player: () -> Void
    private let pauseAction: () -> Void
    private let cancellable: () -> Void
    
    init(getter: @escaping () -> Double, setter: @escaping (Double) -> Void, player: @escaping () -> Void, pause: @escaping () -> Void, cancellable: @escaping () -> Void) {
        self.getter = getter
        self.setter = setter
        self.player = player
        self.pauseAction = pause
        self.cancellable = cancellable
    }
    
    public func play() {
        player()
    }
    
    public func cancel() {
        cancellable()
    }
    
    public func pause() {
        pauseAction()
    }
    
    public func stop(_ position: AnimationPosition) -> AnimationPosition {
        position
    }
    
}
