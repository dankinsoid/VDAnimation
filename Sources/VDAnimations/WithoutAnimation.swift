//
//  WithoutAnimation.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public struct WithoutAnimation: ClosureAnimation {
    
    public var modified: ModifiedAnimation {
        ModifiedAnimation(
            options: AnimationOptions.empty.chain.duration[.absolute(0)].isInstant[true],
            animation: self
        )
    }
    
    private let block: () -> ()
    private let initial: (() -> ())?
    
    public init(_ closure: @escaping () -> ()) {
        block = closure
        initial = nil
    }
    
    public init(_ closure: @escaping () -> (), onReverse: @escaping () -> ()) {
        block = closure
        initial = onReverse
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        let duration = options.duration?.absolute ?? 0
        let anim = options.isReversed ? (initial ?? block) : block
        if duration == 0 {
            execute(anim, completion)
            return .end
        } else {
            let remote = RemoteDelegate(completion)
            DispatchTimer.execute(seconds: duration) {
                guard !remote.isStopped else { return }
                self.execute(anim, completion)
            }
            return remote.delegate
        }
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        let end = options.isReversed ? position.reversed : position
        switch end.complete {
        case 1:     execute(block) {_ in}
        default:    break
        }
    }
    
    private func execute(_ block: () -> (), _ completion: @escaping (Bool) -> ()) {
        UIView.performWithoutAnimation(block)
        completion(true)
    }
    
}
