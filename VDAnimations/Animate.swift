//
//  Animate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import SwiftUI

///SwiftUI animation
@available(iOS 13.0, macOS 10.15, *)
public struct Animate: AnimationProviderProtocol {
    private let block: () -> ()
    
    public init(_ block: @escaping () -> ()) {
        self.block = block
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        var animation: Animation?
        if let dur = options.duration?.absolute {
            if let curve = options.curve {
                animation = .timingCurve(Double(curve.point1.x), Double(curve.point1.y), Double(curve.point2.x), Double(curve.point2.y), duration: dur)
            } else {
                animation = .linear(duration: dur)
            }
        } else {
            animation = nil
        }
        if let count = options.repeatCount, count > 1 || options.autoreverses == true {
            let reverse = options.autoreverses ?? true
            if count < .max {
                animation = animation?.repeatCount(count, autoreverses: reverse)
            } else {
                animation = animation?.repeatForever(autoreverses: reverse)
            }
        }
        withAnimation(animation) {[block] in
            block()
        }
        Timer.scheduledTimer(withTimeInterval: options.duration?.absolute ?? 0, repeats: false) { _ in
            completion(true)
        }
    }
    
    public func canSet(state: AnimationState) -> Bool {
        switch state {
        case .start:    return false
        case .progress: return false
        case .end:      return true
        }
    }
    
    public func set(state: AnimationState) {
        switch state {
        case .start:    return
        case .progress: return
        case .end:      block()
        }
    }
}
