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
//    var priority: OptionsPriority = .usual
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
    
    public var complete: Double {
        switch self {
        case .start:            return 0
        case .progress(let k):  return k
        case .end:              return 1
        }
    }
}

enum OptionsPriority: Double, Comparable {
    case usual = 0, required = 1
    
    static func <(lhs: OptionsPriority, rhs: OptionsPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
}
