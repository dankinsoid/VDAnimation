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
        ModifiedAnimation(options: AnimationOptions.empty.chain.duration[.absolute(0)], animation: self)
    }
    
    private let block: () -> ()
    
    public init(_ closure: @escaping () -> ()) {
        block = closure
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        let duration = options.duration?.absolute ?? 0
        if duration == 0 {
            execute(completion)
            return .end
        } else {
            let remote = RemoteDelegate(completion)
            execute { result in
                DispatchTimer.execute(seconds: duration) {
                    guard !remote.isStopped else { return }
                    completion(result)
                }
            }
            return remote.delegate
        }
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions) {
        let end = options.isReversed ? position.reversed : position
        if end.complete == 1 { execute({_ in}) }
    }
    
    private func execute(_ completion: @escaping (Bool) -> ()) {
        UIView.performWithoutAnimation(block)
        completion(true)
    }
    
}
