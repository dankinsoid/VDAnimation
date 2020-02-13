//
//  AnimationDelegate.swift
//  CA
//
//  Created by Daniil on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation


public struct AnimationDelegate {
    public static let empty = AnimationDelegate { $0 }
    public static let end = AnimationDelegate {_ in .end }
    
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
    var completion: ((Bool) -> ())?
    var isStopped: Bool { position != nil }
    
    init(_ completion: ((Bool) -> ())? = nil) {
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
    
    var asDelegate: AnimationDelegate {
        AnimationDelegate {
            self.delegate.stop($0)
        }
    }
}
