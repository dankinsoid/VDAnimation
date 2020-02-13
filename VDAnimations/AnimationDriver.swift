//
//  AnimationDelegate.swift
//  CA
//
//  Created by Daniil on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public protocol AnimationStopable

public struct AnimationDelegate {
    public let stop: (AnimationState) -> AnimationState
    
    public func stop() {
        stop(.end)
    }
    
}
