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
    
    var absolute: TimeInterval? {
        if case .absolute(let value) = self { return value }
        return nil
    }
    
    var relative: Double? {
        if case .relative(let value) = self { return value }
        return nil
    }
}
