//
//  AnimationDuration.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public enum AnimationDuration {
    case absolute(TimeInterval), relative(Double)
    
    public var absolute: TimeInterval? {
        if case .absolute(let value) = self { return value }
        return nil
    }
    
    public var relative: Double? {
        if case .relative(let value) = self { return value }
        return nil
    }
    
}

public func /<F: BinaryFloatingPoint>(_ lhs: AnimationDuration, _ rhs: F) -> AnimationDuration {
    switch lhs {
    case .absolute(let value): return .absolute(value / Double(rhs))
    case .relative(let value): return .relative(value / Double(rhs))
    }
}

public func *<F: BinaryFloatingPoint>(_ lhs: AnimationDuration, _ rhs: F) -> AnimationDuration {
    switch lhs {
    case .absolute(let value): return .absolute(value * Double(rhs))
    case .relative(let value): return .relative(value * Double(rhs))
    }
}

public func *<F: BinaryFloatingPoint>(_ lhs: F, _ rhs: AnimationDuration) -> AnimationDuration {
    rhs * lhs
}
