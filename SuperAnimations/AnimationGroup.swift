//
//  AnimationGroup.swift
//  SuperAnimations
//
//  Created by Daniil on 22.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class AnimationGroup {
    
    public init(_ animations: [AnimatorProtocol]) {
          // self.animations = animations
       }
       
       public convenience init(_ animations: AnimatorProtocol...) {
           self.init(animations)
       }
       
       public convenience init(@AnimatorBuilder _ animations: () -> ()) {
           animations()
           self.init()
       }
       
       public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
           self.init(animations())
       }
       
       public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
           self.init(animations())
       }
       
    
}
