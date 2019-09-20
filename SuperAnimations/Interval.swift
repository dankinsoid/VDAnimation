//
//  Interval.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public struct Interval: ExpressibleByFloatLiteral {
    public var isRunning: Bool = false
    public var progress: Double = 0
    
    public init(_ value: Double) {}
    
    public init(floatLiteral value: Double) {
        self = Interval(value)
    }
    
    public func start(_ completion: ((UIViewAnimatingPosition) -> ())?) {}
    public func pause() {}
    public func stop() {}
}
