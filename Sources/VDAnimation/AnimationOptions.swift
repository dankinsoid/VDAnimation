//
//  AnimationOptions.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public struct AnimationOptions {
    static let empty = AnimationOptions()
    public var duration: AnimationDuration?
    public var isInstant = false
    public var curve: BezierCurve?
    public var autoreverseStep: AutoreverseStep?
    
    var chain: ValueChaining<AnimationOptions> { ValueChaining(self) }
    
    public func or(_ other: AnimationOptions) -> AnimationOptions {
        AnimationOptions(
            duration: duration ?? other.duration,
            curve: curve ?? other.curve,
            autoreverseStep: autoreverseStep ?? other.autoreverseStep
        )
    }
    
}

extension AnimationOptions {
    var isReversed: Bool { autoreverseStep == .back }
}

public enum AnimationPosition: ExpressibleByFloatLiteral {
    case start, progress(Double), end
    
    public var complete: Double {
        switch self {
        case .start:            return 0
        case .progress(let k):  return k
        case .end:              return 1
        }
    }
    
    public var reversed: AnimationPosition {
        switch self {
        case .start:            return .end
        case .progress(let k):  return .progress(1 - k)
        case .end:              return .start
        }
    }
    
    public init(floatLiteral value: Double) {
        switch value {
        case 0: self = .start
        case 1: self = .end
        default: self = .progress(value)
        }
    }
    
}

enum OptionsPriority: Double, Comparable {
    case usual = 0, required = 1
    
    static func <(lhs: OptionsPriority, rhs: OptionsPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
}

public enum AutoreverseStep {
    case forward, back
    
    public var inverted: AutoreverseStep {
        switch self {
        case .forward:  return .back
        case .back:     return .forward
        }
    }
}
