//
//  Parallel.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct Parallel: AnimationProviderProtocol {
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
        let parallelCompletion = ParallelCompletion(animations.enumerated().map { arg in
            { arg.element.start(with: array[arg.offset], $0) }
        })
        parallelCompletion.start(completion: completion)
    }
    
    private func getOptions(for options: AnimationOptions?) -> [AnimationOptions?] {
        guard !animations.isEmpty else { return [] }
        if let dur = options?.duration?.absolute {
            return setDuration(duration: dur, options: options)
        } else {
            let dur = animations.reduce(0, { max($0, $1.modificators.duration?.absolute ?? 0) })
            return setDuration(duration: dur, options: options)
        }
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions?) -> [AnimationOptions?] {
        guard !animations.isEmpty else { return [] }
        let maxDuration = animations.reduce(0, { max($0, $1.modificators.duration?.absolute ?? 0) })
        let k = maxDuration == 0 ? 1 : full / maxDuration
        let childrenDurations: [Double] = animations.map {
            guard let setted = $0.modificators.duration else {
                return full
            }
            switch setted {
            case .absolute(let time):   return time * k
            case .relative(let r):      return full * min(1, r)
            }
        }
        var result = childrenDurations.map({ AnimationOptions(duration: .absolute($0)) as AnimationOptions? })
        setCurve(&result, duration: full, options: options)
        return result
    }
    
    private func setCurve(_ array: inout [AnimationOptions?], duration: Double, options: AnimationOptions?) {
        guard let fullCurve = options?.curve, fullCurve != .linear else {
            return
        }
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
            return Array(repeating: 0...1, count: array.count)
        }
        var progresses: [ClosedRange<Double>] = []
        for anim in array {
            let end = (anim?.duration?.absolute ?? 0) / duration
            progresses.append(0...end)
        }
        return progresses
    }
    
}

fileprivate final class ParallelCompletion {
    typealias T = (Bool) -> ()
    let common: Int
    var current = 0
    let functions: [(@escaping T) -> ()]
    
    init(_ functions: [(@escaping T) -> ()]) {
        self.common = functions.count
        self.functions = functions
    }
    
    func start(completion: @escaping T) {
        for function in functions {
            function { state in
                self.current += 1
                if self.current == self.common {
                    self.current = 0
                    completion(state)
                }
            }
        }
    }
    
}
