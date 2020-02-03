//
//  AnimationOptions.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct AnimationOptions {
    static let empty = AnimationOptions()
    public var duration: AnimationDuration?
    public var curve: BezierCurve?
    var chain: Chainer<AnimationOptions> { Chainer(root: self) }
    
    public func or(_ other: AnimationOptions) -> AnimationOptions {
        AnimationOptions(
            duration: duration ?? other.duration,
            curve: curve ?? other.curve
        )
    }
}

public enum AnimationState {
    case start, progress(Double), end
}
