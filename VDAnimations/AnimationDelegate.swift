//
//  AnimationDelegate.swift
//  CA
//
//  Created by Daniil on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation


public struct AnimationDelegate {
    private let stopAction: (AnimationPosition) -> AnimationPosition
    
    public init(_ action: @escaping (AnimationPosition) -> AnimationPosition) {
        stopAction = action
    }
    
    @discardableResult
    public func stop(_ position: AnimationPosition = .end) -> AnimationPosition {
        stopAction(position)
    }
    
}