//
//  AnimateProperty.swift
//  CA
//
//  Created by Daniil on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

struct RepeatAnimation<A: VDAnimationProtocol>: VDAnimationProtocol {
    private let count: Int?
    private let animation: A
    var modified: ModifiedAnimation {
        ModifiedAnimation(options: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    private let duration: AnimationDuration?
    
    init(_ cnt: Int?, for anim: A) {
        count = cnt
        animation = anim
        duration = RepeatAnimation.duration(for: cnt, from: anim.options.duration)
    }
    
    func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        if let i = count {
            let cnt = max(0, i)
            guard cnt > 0 else {
                completion(true)
                return
            }
            start(with: options, completion, i: 0, condition: { $0 < cnt })
        } else {
            start(with: options, completion, i: 0, condition: { _ in true })
        }
    }
    
    private func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> (), i: Int, condition: @escaping (Int) -> Bool) {
        let index = options.isReversed ? (count ?? (i + 1)) - i - 1 : i
        guard condition(i) else {
            completion(true)
            return
        }
        let option = getOptions(options: options, i: index)
        if i > 0 {
            let reverse = option.autoreverseStep?.inverted ?? .back
            animation.start(with: option.chain.autoreverseStep[reverse].duration[.absolute(0)]) {
                guard $0 else { return completion(false) }
                self.animation.start(with: option) {
                    guard $0 else { return completion(false) }
                    self.start(with: options, completion, i: max(0, i &+ 1), condition: condition)
                }
            }
        } else {
            animation.start(with: option) {
                guard $0 else { return completion(false) }
                self.start(with: options, completion, i: max(0, i &+ 1), condition: condition)
            }
        }
    }
    
    func set(position: AnimationPosition, for options: AnimationOptions) {
        let position = options.isReversed == true ? position.reversed : position
        switch position {
        case .start, .end:
            animation.set(position: position)
        case .progress(let k):
            if count != nil {
                animation.set(position: .progress(getProgress(for: k)))
            } else {
                animation.set(position: position)
            }
        }
    }
    
    private func getProgress(for progress: Double) -> Double {
        guard let cnt = count, cnt > 0, progress != 1 else { return progress }
        let k = (progress * Double(cnt))
        return k.truncatingRemainder(dividingBy: 1)
    }
    
    private static func duration(for count: Int?, from dur: AnimationDuration?) -> AnimationDuration? {
        guard let cnt = count, let duration = dur, cnt > 0 else { return nil }
        switch duration {
        case .absolute(let time):   return .absolute(time * Double(cnt))
        case .relative(let time):   return .relative(time)
        }
    }
    
    private func getOptions(options: AnimationOptions, i: Int) -> AnimationOptions {
        let full = options.duration?.absolute ?? duration?.absolute ?? animation.options.duration?.absolute ?? 0
        var result = options
        result.autoreverseStep = result.autoreverseStep ?? .forward
        guard let fullCurve = options.curve, fullCurve != .linear else {
            result.duration = .absolute(full / Double(count ?? 1))
            return result
        }
        let progresses = getProgress(i: i)
        let (curve1, newDuration) = fullCurve.split(range: progresses)
        result.duration = .absolute(full * newDuration)
        result.curve = curve1
        return result
    }
    
    private func getProgress(i: Int) -> ClosedRange<Double> {
        guard let cnt = count, cnt > 1 else { return 0...1 }
        let lenght = 1 / Double(cnt)
        var progress = (lenght * Double(i)...(lenght * Double(i) + lenght))
        if i == cnt - 1 {
            progress = min(1, progress.lowerBound)...1
        }
        return progress
    }
    
}
