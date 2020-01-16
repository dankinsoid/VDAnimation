//
//  AnimatorBuilder.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

@_functionBuilder
public struct AnimatorBuilder {
    
//    public static func buildBlock() {}
    
    public static func buildBlock(_ animations: AnimationProviderProtocol...) -> [AnimationProviderProtocol] {
        return animations
    }
    
//    public static func buildBlock(_ animation: AnimationProviderProtocol) -> AnimationProviderProtocol {
//        return animation
//    }
//
//    public static func buildBlock() -> [AnimationProviderProtocol] {
//        return []
//    }
    
}
