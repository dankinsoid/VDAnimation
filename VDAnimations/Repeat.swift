//
//  AnimateProperty.swift
//  CA
//
//  Created by Daniil on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

struct RepeatAnimation<A: AnimationProviderProtocol>: AnimationProviderProtocol {
    private let count: Int?
    private let animation: A
    var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    private let duration: AnimationDuration?
    
    init(_ cnt: Int?, for anim: A) {
        count = cnt
        animation = anim
        duration = RepeatAnimation.duration(for: cnt, from: anim.modificators.duration)
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
        let i = options.isReversed ? (count ?? (i + 1)) - i - 1 : i
        guard condition(i) else {
            completion(true)
            return
        }
        let option = getOptions(options: options, i: i)
        if i > 0, animation.canSet(state: .start, for: option) {
            animation.set(state: .start, for: option)
        }
        animation.start(with: option) {
            if $0 {
                self.start(with: options, completion, i: max(0, i &+ 1), condition: condition)
            } else {
                completion($0)
            }
        }
    }
    
    func canSet(state: AnimationState, for options: AnimationOptions) -> Bool {
        switch state {
        case .start, .end: return animation.canSet(state: state, for: options)
        case .progress(let k):
            if count != nil {
                return animation.canSet(state: .progress(getProgress(for: k)), for: options)
            } else {
                return animation.canSet(state: state, for: options)
            }
        }
    }
    
    func set(state: AnimationState, for options: AnimationOptions) {
        let state = options.isReversed == true ? state.reversed : state
        switch state {
        case .start, .end:
            animation.set(state: state)
        case .progress(let k):
            if count != nil {
                animation.set(state: .progress(getProgress(for: k)))
            } else {
                animation.set(state: state)
            }
        }
    }
    
    private func getProgress(for progress: Double) -> Double {
        guard let cnt = count, cnt > 0 else { return progress }
        return (progress * Double(cnt)).truncatingRemainder(dividingBy: 1)
    }
    
    private static func duration(for count: Int?, from dur: AnimationDuration?) -> AnimationDuration? {
        guard let cnt = count, let duration = dur, cnt > 0 else { return nil }
        switch duration {
        case .absolute(let time):   return .absolute(time * Double(cnt))
        case .relative(let time):   return .relative(time)
        }
    }
    
    private func getOptions(options: AnimationOptions, i: Int) -> AnimationOptions {
        let full = options.duration?.absolute ?? duration?.absolute ?? animation.modificators.duration?.absolute ?? 0
        var result = options
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
