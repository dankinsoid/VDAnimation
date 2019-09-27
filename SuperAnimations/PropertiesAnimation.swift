//
//  PropertiesAnimation.swift
//  SuperAnimations
//
//  Created by crypto_user on 27/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class PropertiesAnimation: AnimatorProtocol {
    public var progress: Double = 0.0
    public var isRunning: Bool = false
    public var state: UIViewAnimatingState = .inactive
    public var timing: Animate.Timing = .default
    public var parameters: AnimationParameters = .default
    private let animator: CAKeyframeAnimation
    private weak var layer: CALayer?
    
    init() {
        layer?.model()
        CAKeyframeAnimation()
            //.timingFunctions = [CAMediaTimingFunction.init(controlPoints: <#T##Float#>, <#T##c1y: Float##Float#>, <#T##c2x: Float##Float#>, <#T##c2y: Float##Float#>)]
        UIView().layer.add(<#T##anim: CAAnimation##CAAnimation#>, forKey: <#T##String?#>)
    }
    
    public func copy(with parameters: AnimationParameters) -> Self {
        
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        
    }
    
    public func pause() {
        
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        
    }
    
    
}
