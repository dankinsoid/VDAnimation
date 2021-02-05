//
//  Autoreverse.swift
//  CA
//
//  Created by Daniil on 09.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

struct Autoreverse<Animation: VDAnimationProtocol>: VDAnimationProtocol {
    private let animation: Animation
    var modified: ModifiedAnimation {
        ModifiedAnimation(options: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    private let duration: AnimationDuration?
    
    init(_ animation: Animation) {
        self.animation = animation
        self.duration = Autoreverse.duration(from: animation.options.duration)
    }
    
    @discardableResult
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) -> AnimationDelegate {
        let result = MutableDelegate()
        result.delegate = animation.start(with: self.options(from: options, step: .forward)) {
            guard $0 else { return completion(false) }
            result.delegate = self.animation.start(with: self.options(from: options, step: .back), completion)
        }
        return delegate(for: result)
    }
    
    private func delegate(for mutable: MutableDelegate) -> AnimationDelegate {
        AnimationDelegate {
            mutable.delegate.stop(self.targetPosition(for: $0))
            return $0
        }
    }
    
    func set(position: AnimationPosition, for options: AnimationOptions) {
        let option = options.chain.autoreverseStep[nil]
        animation.set(position: targetPosition(for: position), for: option)
    }
    
    private func targetPosition(for position: AnimationPosition) -> AnimationPosition {
        switch position {
        case .start, .end:      return .start
        case .progress(let k):  return .progress(1 - abs(k - 0.5) * 2)
				case .current:					return .current
        }
    }
    
    private func options(from options: AnimationOptions, step: AutoreverseStep) -> AnimationOptions {
        var result = options
        setCurve(for: &result, step: step)
        result.autoreverseStep = step
        return result
    }
    
    private func setCurve(for options: inout AnimationOptions, step: AutoreverseStep) {
        guard let duration = options.duration else { return }
        guard let fullCurve = options.curve, fullCurve != .linear else {
            options.duration = duration / 2
            return
        }
        let progress = step == .forward ? 0...0.5 : 0.5...1
        var (curve1, newDuration) = fullCurve.split(range: progress)
        if let curve2 = animation.options.curve {
            curve1 = BezierCurve.between(curve1, curve2)
        }
        options.duration = duration * newDuration
        options.curve = curve1
    }
    
    private static func duration(from dur: AnimationDuration?) -> AnimationDuration? {
        guard let duration = dur else { return nil }
        switch duration {
        case .absolute(let time):   return .absolute(time * 2)
        case .relative(let time):   return .relative(time)
        }
    }
}
