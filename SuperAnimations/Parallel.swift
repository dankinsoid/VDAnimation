//
//  Parallel.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class Parallel: AnimatorProtocol {
    public var parameters: AnimationParameters
    public var state: UIViewAnimatingState = .inactive
    public var isRunning: Bool = false
    public var progress: Double {
        get { getProgress() }
        set { setProgress(newValue) }
    }
    private var firstStart = true
    public var timing: Animate.Timing { getTiming() }
    private var _timing: Animate.Timing?
    var animations: [AnimatorProtocol]
    private var completion: ParallelCompletion?
    
    init(_ animations: [AnimatorProtocol], parameters: AnimationParameters = .default) {
        self.animations = animations
        self.parameters = parameters
        configureChildren()
    }
    
    public convenience init(animations: [AnimatorProtocol]) {
        self.init(animations, parameters: .default)
    }
    
    public convenience init(_ animations: AnimatorProtocol...) {
        self.init(animations)
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> ()) {
        animations()
        self.init()
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> AnimatorProtocol) {
        self.init(animations())
    }
    
    public convenience init(@AnimatorBuilder _ animations: () -> [AnimatorProtocol]) {
        self.init(animations())
    }
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        guard !isRunning else {
            self.completion?.add(completion: completion)
            return
        }
        configureChildren()
        self.completion = ParallelCompletion(common: animations.count, functions: animations.map({ $0.start }))
        self.completion?.start {
            self.parameters.completion($0)
            completion($0)
        }
    }
    
    public func pause() {
        animations.forEach { $0.pause() }
    }
    
    public func stop(at position: UIViewAnimatingPosition) {
        animations.forEach { $0.stop(at: position) }
    }
    
    public func copy(with parameters: AnimationParameters) -> Parallel {
        return Parallel(animations, parameters: parameters)
    }
    
    private func configureChildren() {
        guard firstStart else { return }
        setDuration()
        firstStart = false
    }
   
    private func getTiming() -> Animate.Timing {
        if let dur = parameters.settedTiming.duration?.fixed {
            return Animate.Timing(duration: dur, curve: parameters.settedTiming.curve ?? .linear)
        } else if let computed = _timing {
            return computed
        } else {
            let dur = animations.reduce(0, { max($0, $1.timing.duration) })
            let result = Animate.Timing(duration: dur, curve: parameters.settedTiming.curve ?? .linear)
            _timing = result
            return result
        }
    }
    
    private func setDuration() {
        guard !animations.isEmpty else { return }
        let full = timing.duration
        let maxDuration = animations.reduce(0, { max($0, $1.timing.duration) })
        let k = maxDuration == 0 ? 1 : full / maxDuration
        let childrenDurations: [Double]
        if maxDuration == 0 || full == 0 {
            childrenDurations = [Double](repeating: full, count: animations.count)
        } else {
            childrenDurations = animations.map {
                if let setted = $0.parameters.settedTiming.duration {
                    switch setted {
                    case .absolute(let time):
                        return time * k
                    case .relative(let r):
                        return full * min(1, r)
                    }
                }
                return full
            }
        }
        setCurve(childrenDurations)
    }
    
    private var progresses: [ClosedRange<Double>] = []
    
    private func setCurve(_ durations: [Double]) {
        setProgresses(durations)
        guard let fullCurve = parameters.settedTiming.curve, fullCurve != .linear else {
            for i in 0..<animations.count {
                animations[i].set(duration: durations[i], curve: nil)
            }
            return
        }
//        var newD: [String] = [timing.curve.exportWith(name: "common")]
//        var newT: [Double] = []
        for i in 0..<animations.count {
            var (curve1, newDuration) = fullCurve.split(range: progresses[i])
            if let curve2 = animations[i].parameters.settedTiming.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
//            newD.append(curve1.exportWith(name: "curve\(i)"))
//            newT.append(newDuration)
            animations[i].set(duration: timing.duration * newDuration, curve: curve1)
        }
//        print("{\(newD.joined(separator: ","))}")
//        print(durations.reduce(0, +))
//        print(timing.duration)
//        print(durations.map({ $0 / timing.duration }))
//        print(newT.reduce(0, +))
//        print(newT)
//        print()
    }
    
    
    private func setProgresses(_ durations: [Double]) {
        progresses = []
        guard !animations.isEmpty else { return }
        guard timing.duration > 0 else {
            progresses = Array(repeating: 0...1, count: durations.count)
            return
        }
        for anim in durations {
            let end = anim / timing.duration
            progresses.append(0...end)
        }
    }
    
    private func getProgress() -> Double {
        configureChildren()
        guard !animations.isEmpty else { return 1 }
        for i in 0..<animations.count {
            if animations[i].progress < 1, progresses[i].upperBound > 0 {
                return progresses[i].upperBound * animations[i].progress
            }
        }
        return 1
    }
    
    private func setProgress(_ value: Double) {
        guard !animations.isEmpty else { return }
        configureChildren()
        for i in 0..<animations.count {
            let upper = progresses[i].upperBound
            if upper > 0 {
                animations[i].progress = min(1, value / upper)
            } else {
                animations[i].progress = 1
            }
        }
    }
}

fileprivate final class ParallelCompletion {
    typealias T = (UIViewAnimatingPosition) -> ()
    let common: Int
    var current = 0
    var observers: [UUID: T] = [:]
    let functions: [(@escaping T) -> ()]
    
    init(common: Int, functions: [(@escaping T) -> ()]) {
        self.common = common
        self.functions = functions
    }
    
    func add(completion: @escaping (UIViewAnimatingPosition) -> ()) {
        let id = UUID()
        observers[id] = completion
    }
    
    func start(completion: @escaping T) {
        add(completion: completion)
        for function in functions {
            function {[weak self] state in
                self?.current += 1
                if self?.current == self?.common {
                    self?.current = 0
                    self?.observers.forEach {
                        $0.value(state)
                    }
                }
            }
        }
    }
    
}
