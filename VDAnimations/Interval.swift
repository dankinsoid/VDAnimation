//
//  Interval.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct Interval: AnimationProviderProtocol {
    
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    public let duration: AnimationDuration?
    
    public init(_ duration: Double) {
        self.duration = .absolute(duration)
    }
    
    public init(relative: Double) {
        duration = .relative(relative)
    }
    
    public init() {
        duration = nil
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        Timer.scheduledTimer(withTimeInterval: options.duration?.absolute ?? duration?.absolute ?? 0, repeats: false) { _ in
            completion(true)
        }
    }
    
    public func canSet(state: AnimationState) -> Bool { true }
    public func set(state: AnimationState) {}
    
}
