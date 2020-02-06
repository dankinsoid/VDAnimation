//
//  VDViewAnimator.swift
//  SuperAnimations
//
//  Created by Daniil on 21.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

class VDViewAnimator: UIViewPropertyAnimator {
    
    deinit {
        finishAnimation(at: .end)
    }
    
    override func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
        guard state != .inactive else { return }
        if state == .active {
            stopAnimation(false)
        }
        super.finishAnimation(at: finalPosition)
    }
    
}
