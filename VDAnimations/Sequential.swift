//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation

public struct Sequential: AnimationProviderProtocol {
    private let animations: [AnimationProviderProtocol]
    
    private init(_ animations: [AnimationProviderProtocol]) {
        self.animations = animations
    }
    
    public init(_ animations: AnimationProviderProtocol...) {
        self = .init(animations)
    }
    
    public init(@AnimatorBuilder _ animations: () -> [AnimationProviderProtocol]) {
        self = .init(animations())
    }
    
    public func start(with options: AnimationOptions?, _ completion: @escaping (Bool) -> ()) {
        let array = getOptions(for: options)
        start(completion, index: 0, options: array)
    }
    
    private func start(_ completion: @escaping (Bool) -> (), index: Int, options: [AnimationOptions?]) {
        guard index < animations.count else {
            completion(true)
            return
        }
        animations[index].start(with: options[index]) {
            guard $0 else {
                return completion(false)
            }
            self.start(completion, index: index + 1, options: options)
        }
    }
    
    private func getOptions(for options: AnimationOptions?) -> [AnimationOptions?] {
        guard !animations.isEmpty else { return [] }
        if let dur = options?.duration?.absolute {
            return setDuration(duration: dur, options: options)
        } else {
            let dur = animations.reduce(0, { $0 + ($1.modificators.duration?.absolute ?? 0) })
            var rel = min(1, animations.reduce(0, { $0 + ($1.modificators.duration?.relative ?? 0) }))
            rel = rel == 1 ? 0 : rel
            let full = dur / (1 - rel)
            return setDuration(duration: full, options: options)
        }
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions?) -> [AnimationOptions?] {
        guard !animations.isEmpty else { return [] }
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.modificators.duration?.absolute {
                k = absolute / full
            } else if let relative = anim.modificators.duration?.relative {
                k = relative
            }
            childrenRelativeTime += k ?? 0
            ks.append(k)
        }
        let cnt = ks.filter({ $0 == nil }).count
        let relativeK = cnt > 0 ? max(1, childrenRelativeTime) : childrenRelativeTime
        var add = (1 - min(1, childrenRelativeTime))
        if cnt > 0 {
            add /= Double(cnt)
        }
        var result: [AnimationOptions?]
        if relativeK == 0 {
            result = [AnimationOptions?](repeating: AnimationOptions(duration: .absolute(full / Double(animations.count))), count: animations.count)
        } else {
            result = ks.map({ AnimationOptions(duration: .absolute(full * ($0 ?? add) / relativeK)) })
        }
        setCurve(&result, duration: full, options: options)
        return result
    }
    
    private func setCurve(_ array: inout [AnimationOptions?], duration: Double, options: AnimationOptions?) {
        guard let fullCurve = options?.curve, fullCurve != .linear else { return }
        let progresses = getProgresses(array, duration: duration, options: options)
        for i in 0..<animations.count {
            var (curve1, newDuration) = fullCurve.split(range: progresses[i])
            if let curve2 = animations[i].modificators.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
            array[i]?.duration = .absolute(duration * newDuration)
            array[i]?.curve = curve1
        }
    }

    private func getProgresses(_ array: [AnimationOptions?], duration: Double, options: AnimationOptions?) -> [ClosedRange<Double>] {
        guard !array.isEmpty else { return [] }
        guard duration > 0 else {
            return Array(repeating: 0...0, count: array.count)
        }
        var progresses: [ClosedRange<Double>] = []
        var dur = 0.0
        var start = 0.0
        for anim in array {
            dur += anim?.duration?.absolute ?? 0
            let end = min(1, dur / duration)
            progresses.append(start...end)
            start = end
        }
        progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
        return progresses
    }
    
}
