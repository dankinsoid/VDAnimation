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
    public var repeatCount: Int = 1
    public var autoreverses: Bool = false
}
