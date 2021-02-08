//
//  SwiftUIAnimate.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import SwiftUI

///SwiftUI animation
@available(iOS 13.0, macOS 10.15, *)
public struct SwiftUIAnimate: ClosureAnimation {
    private let block: () -> Void
    
    public init(_ block: @escaping () -> Void) {
        self.block = block
    }
    
    @discardableResult
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegate {
        guard let dur = options.duration?.absolute, dur > 0 else {
            completion(true)
            return .end
        }
        let animation: Animation
        if let curve = options.curve {
            animation = .timingCurve(Double(curve.point1.x), Double(curve.point1.y), Double(curve.point2.x), Double(curve.point2.y), duration: dur)
        } else {
            animation = .linear(duration: dur)
        }
        withAnimation(animation) {[block] in
            block()
        }
        Timer.scheduledTimer(withTimeInterval: options.duration?.absolute ?? 0, repeats: false) { _ in
            completion(true)
        }
        return .empty
    }
    
    public func set(position: AnimationPosition, for options: AnimationOptions, execute: Bool = true) {
        switch position {
        case .start:    break
        case .progress: break
				case .current:	break
        case .end:      block()
        }
    }
}
