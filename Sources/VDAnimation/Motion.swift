import Foundation

public protocol Motion<Value> {

    associatedtype Value
    var anyMotion: AnyMotion<Value> { get }
}

public enum Duration {

    case absolute(Double)
    case relative(Double)
    
    public static let zero = Duration.absolute(0)
    public static var `default` = Duration.absolute(0.25)
    
    public var seconds: Double? {
        if case let .absolute(double) = self {
            return double
        }
        return nil
    }
    
    public var relative: Double? {
        if case let .relative(double) = self {
            return double
        }
        return nil
    }
    
    public static func /(_ lhs: Duration, _ rhs: Double) -> Duration {
        switch lhs {
        case .absolute(let double):
            return .absolute(double / rhs)
        case .relative(let double):
            return .relative(double / rhs)
        }
    }

    public static func *(_ lhs: Duration, _ rhs: Double) -> Duration {
        switch lhs {
        case .absolute(let double):
            return .absolute(double * rhs)
        case .relative(let double):
            return .relative(double * rhs)
        }
    }
}

public struct AnyMotion<Value>: Motion {
    
    public let prepare: (Value, Duration?) -> MotionData<Value>
    
    public var anyMotion: AnyMotion<Value> { self }
}

public struct MotionData<Value> {

    public var duration: Duration?
    public var lerp: (Value, Double) -> Value
    public var sideEffects: ((ClosedRange<Double>) -> [(Value) -> Void])?
    
    public init(
        duration: Duration?,
        lerp: @escaping (Value, Double) -> Value,
        sideEffects: ((ClosedRange<Double>) -> [(Value) -> Void])? = nil
    ) {
        self.duration = duration
        self.lerp = lerp
        self.sideEffects = sideEffects
    }
}

public struct From<Value>: Motion {

    public let value: Value
    public let motion: AnyMotion<Value>

    public init(_ value: Value, @MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.value = value
        self.motion = motion()
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            var result = motion.anyMotion.prepare(value, dur)
            let lerp = result.lerp
            result.lerp = { _, t in lerp(value, t) }
            return result
        }
    }
}

public struct Sequential<Value>: Motion {
    
    public let motions: () -> [AnyMotion<Value>]
    
    public init(@MotionsArrayBuilder<Value> _ motions: @escaping () -> [AnyMotion<Value>]) {
        self.motions = motions
    }
    
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { initialValue, expDur in
            // Accumulation state structure
            
            // Reduce over all motions to prepare them
            var state = MotionState(lastValue: initialValue)
            
            for motion in motions() {
                let info = motion.prepare(state.lastValue, nil)
                let nextValue = info.lerp(state.lastValue, 1.0)
                let duration = info.duration?.seconds
                let relative = (info.duration?.relative).map(clamp)
                
                // Update state
                state.lastValue = nextValue
                if let duration = duration {
                    state.sumAbs = (state.sumAbs ?? 0.0) + duration
                }
                state.sumRel += relative ?? 0.0
                state.cntAny += (duration != nil || relative != nil) ? 0 : 1
                state.cntAbs += duration != nil ? 1 : 0
                if let duration, let relativeDuration = info.duration?.relative, relativeDuration > 0 {
                    state.intrDur = duration / relativeDuration
                }
                state.items.append(info)
                state.effectsCnt += info.sideEffects != nil ? 1 : 0
            }
            
            // Process timing calculations
            let relK = state.sumRel > 1 ? 1.0 / state.sumRel : 1.0
            let sumRel = clamp(state.sumRel)
            let minDur: Double?
            if let sumAbs = state.sumAbs, sumRel < 1.0 {
                minDur = sumAbs / (1.0 - sumRel)
            } else {
                minDur = state.sumAbs
            }
            
            let expDurMcs = expDur?.seconds
            
            // Calculate resulting duration
            var possibleDurations: [Double] = []
            if let expDurMcs = expDurMcs {
                possibleDurations.append(expDurMcs)
            }
            if let intrDur = state.intrDur {
                possibleDurations.append(intrDur)
            }
            if state.cntAny == 0, let minDur = minDur {
                possibleDurations.append(minDur)
            }
            
            let resDur = possibleDurations.isEmpty ? nil : possibleDurations.max()
            
            // Calculate duration for motions without explicit duration
            let anyDur: Double
            if state.cntAny > 0 {
                if let resDur = resDur, let minDur = minDur, resDur > 0 {
                    anyDur = ((resDur - minDur) / resDur - sumRel) / Double(state.cntAny)
                } else {
                    anyDur = (1.0 - sumRel) / Double(state.cntAny)
                }
            } else {
                anyDur = 0.0
            }
            
            // Process all items with timing info
            var allItems: [Item] = []
            var t: Double = 0.0
            
            for info in state.items {
                var item = Item(data: info)
                
                let relDur: Double
                if let relativeDuration = info.duration?.relative {
                    relDur = relativeDuration
                } else if let resDur = resDur {
                    if resDur > 0 {
                        if let duration = info.duration?.seconds {
                            relDur = duration / resDur
                        } else {
                            relDur = anyDur
                        }
                    } else {
                        relDur = 1.0 / Double(state.items.count)
                    }
                } else {
                    relDur = anyDur
                }
                
                item.start = t
                item.relDur = relDur
                item.end = t + relDur
                allItems.append(item)
                t = item.end
            }
            
            return MotionData(
                duration: resDur.map(Duration.absolute),
                lerp: { initial, T in
                    var result = initial
                    
                    for item in allItems {
                        if item.relDur > 0 && (item.start <= T && T <= item.end || T <= 0) {
                            let t = item.relDur == 0 ? 1.0 : (T - item.start) / item.relDur
                            var animT = t
                            if item.end < 1 {
                                animT = min(1.0, animT)
                            }
                            if item.start > 0 {
                                animT = max(0.0, animT)
                            }
                            if item.end == 1, T == 1 {
                                animT = 1
                            }
                            if item.start == 0, T == 0, item.relDur > 0 {
                                animT = 0
                            }
                            result = item.data.lerp(result, animT)
                            break
                        } else {
                            result = item.data.lerp(result, 1.0)
                        }
                    }
                    
                    return result
                },
                sideEffects: state.effectsCnt > 0 ? { range in
                    var results: [(Value) -> Void] = []
                    for item in allItems {
                        if let sideEffects = item.data.sideEffects {
                            let bounds = [range.lowerBound, range.upperBound].map {
                                transformEffectT($0, item.start, item.end, item.relDur)
                            }
                            results.append(contentsOf: sideEffects(bounds[0]...bounds[1]))
                        }
                    }
                    
                    return results
                } : nil
            )
        }
    }
    
    func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
    
    private struct MotionState {
        var lastValue: Value
        var sumAbs: Double?
        var sumRel: Double = 0.0
        var cntAny: Int = 0
        var cntAbs: Int = 0
        var intrDur: Double?
        var items: [MotionData<Value>] = []
        var effectsCnt: Int = 0
    }

    private struct Item {
    
        var data: MotionData<Value>
        var start: Double = 0.0
        var end: Double = 0.0
        var relDur: Double = 0.0
    }
}

@dynamicMemberLookup
public struct Parallel<Value>: Motion {
    
    private var motions: (Value) -> [AnyMotion<Value>]
    
    private struct Item {

        let data: MotionData<Value>
        var relative: Double
    }
    
    public init() {
        self.motions = { _ in [] }
    }
    
    public init<Child, ID>(
        children: @escaping (Value) -> [(ID, AnyMotion<Child>)],
        getter: @escaping (Value, ID) -> Child,
        setter: @escaping (inout Value, Child, ID) -> Void
    ) {
        self.motions = { value in
            let children = children(value)
            return children.indices.map { i in
                let (id, motion) = children[i]
                return AnyMotion { value, expDur in
                    let data = motion.prepare(getter(value, id), expDur)
                    return MotionData(
                        duration: expDur,
                        lerp: { value, t in
                            var result = value
                            setter(&result, data.lerp(getter(result, id), t), id)
                            return result
                        },
                        sideEffects: data.sideEffects.map { sideEffects in
                            { range in
                                sideEffects(range).map { effect in
                                    { value in
                                        effect(getter(value, id))
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { value, expDur in
            let expDurInS = expDur?.seconds

            var maxDur: Double? = nil
            var items: [Item] = []
            var sideEffectsCnt = 0
            
            for motion in motions(value) {
                let preparedMotion = motion.anyMotion.prepare(value, expDur)
                
                let duration = preparedMotion.duration?.seconds
                let relativeDuration = preparedMotion.duration?.relative
                let lerp = preparedMotion.lerp
                let sideEffects = preparedMotion.sideEffects
                
                let durAbs: Double? = duration ?? ((relativeDuration != nil && expDurInS != nil) ? (expDurInS! * relativeDuration!) : nil)
                
                if let durAbs = durAbs {
                    maxDur = max(durAbs, maxDur ?? 0.0)
                }
                
                let relDur = relativeDuration ?? ((durAbs != nil && expDurInS != nil && expDurInS! > 0) ? (durAbs! / expDurInS!) : 1.0)
                
                items.append(
                    Item(
                        data: MotionData<Value>(
                            duration: durAbs.map(Duration.absolute),
                            lerp: lerp,
                            sideEffects: sideEffects
                        ),
                        relative: relDur
                    )
                )
                
                if sideEffects != nil {
                    sideEffectsCnt += 1
                }
            }
            
            let fullDur = (expDurInS != nil && maxDur != nil) ? max(expDurInS!, maxDur!) : (expDurInS ?? maxDur)
            
            if let fullDur, fullDur != expDurInS, fullDur > 0 {
                for i in items.indices {
                    items[i].relative = (items[i].data.duration?.seconds).map { $0 / fullDur } ?? 1.0
                }
            }
            
            // Return the result
            return MotionData(
                duration: fullDur.map(Duration.absolute),
                lerp: { from, T in
                    var result = from
                    
                    for item in items {
                        let transformT: (Double) -> Double = { t in
                            if item.relative == 0 {
                                return t == 0.0 ? 0.0 : 1.0
                            } else if item.relative == 1.0 {
                                return t
                            } else {
                                return min(1.0, t / item.relative)
                            }
                        }
                        
                        let t = transformT(T)
                        result = item.data.lerp(result, t)
                    }
                    return result
                },
                sideEffects: sideEffectsCnt > 0 ? { range in
                        var effects: [(Value) -> Void] = []
                        for item in items {
                            if let sideEffects = item.data.sideEffects {
                                let transform: (Double) -> Double = { t in
                                    transformEffectT(t, 0.0, item.relative, item.relative)
                                }
                                effects += sideEffects(transform(range.lowerBound)...transform(range.upperBound))
                            }
                        }
                        return effects
                } : nil
            )
        }
    }
    
    public func at<Child>(_ keyPath: WritableKeyPath<Value, Child>, @MotionBuilder<Child> _ motion: @escaping () -> AnyMotion<Child>) -> Parallel {
        var result = self
        let motions = result.motions
        result.motions = { motions($0) + Parallel(keyPath, motion).motions($0) }
        return result
    }
    
    public subscript<Child>(dynamicMember keyPath: WritableKeyPath<Value, Child>) -> Path<Child> {
        Path<Child> { motion in
            var result = self
            let motions = result.motions
            result.motions = { motions($0) + Parallel(keyPath, motion).motions($0) }
            return result
        }
    }
    
    public struct Path<Child> {
        
        let create: (@escaping () -> AnyMotion<Child>) -> Parallel
        
        public func callAsFunction(@MotionBuilder<Child> _ value: @escaping () -> AnyMotion<Child>) -> Parallel {
            create(value)
        }
    }
}


extension Parallel {

    public init<Child>(
        _ keyPath: WritableKeyPath<Value, Child>,
        @MotionBuilder<Child> _ motion: @escaping () -> AnyMotion<Child>
    ) {
        self.init(
            children: { _ in [((), motion())] },
            getter: { v, _ in v[keyPath: keyPath] },
            setter: { r, v, _ in r[keyPath: keyPath] = v }
        )
    }

    public init<Key: Hashable, Child>(
        @MotionBuilder<Child> _ motion: @escaping (Key) -> AnyMotion<Child>
    ) where Value == [Key: Child] {
        self.init(
            children: { $0.keys.map { ($0, motion($0)) } },
            getter: { $0[$1]! },
            setter: { $0[$2] = $1 }
        )
    }
}

extension Parallel where Value: MutableCollection {

    public init(
        @MotionBuilder<Value.Element> _ motion: @escaping (Value.Index) -> AnyMotion<Value.Element>
    ) {
        self.init(
            children: { $0.indices.map { ($0, motion($0)) } },
            getter: { $0[$1] },
            setter: { $0[$2] = $1 }
        )
    }
}

public struct To<Value: Tweenable>: Motion {

    public let values: [Value]
    public let lerp: (Value, Value, Double) -> Value

    public init(lerp: @escaping (Value, Value, Double) -> Value, _ values: [Value]) {
        self.values = values
        self.lerp = lerp
    }

    public init(lerp: @escaping (Value, Value, Double) -> Value, _ values: Value...) {
        self.init(lerp: lerp, values)
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            return MotionData(duration: dur) { first, t in
                let allValues = [first] + values
                guard t != 0 else { return allValues[0] }
                guard t != 1 else { return allValues[allValues.count - 1] }
                
                // Calculate which segment we're in
                let segments = allValues.count - 1
                let segmentSize = 1.0 / Double(segments)
                let segment = max(0, min(allValues.count - 1, min(segments - 1, Int(t / segmentSize))))
                let nextSegment = max(0, min(allValues.count - 1, segment + 1))
                let segmentT = (t - Double(segment) * segmentSize) / segmentSize
                
                if t < 0 {
                    print(t)
                }
                
                // Lerp between the values in this segment
                return lerp(allValues[segment], allValues[nextSegment], segmentT)
            }
        }
    }
}

extension To where Value: Tweenable {

    public init(_ values: [Value]) {
        self.init(lerp: Value.lerp, values)
    }

    public init(_ values: Value...) {
        self.init(lerp: Value.lerp, values)
    }
}

extension To where Value: Codable {

    @_disfavoredOverload
    public init(_ values: [Value]) {
        self.init(lerp: Value.lerp, values)
    }

    @_disfavoredOverload
    public init(_ values: Value...) {
        self.init(lerp: Value.lerp, values)
    }
}


public struct Wait<Value>: Motion {

    public let duration: Duration?

    public init(_ duration: Duration? = nil) {
        self.duration = duration
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            MotionData(duration: duration ?? dur) { value, _ in
                value
            }
        }
    }
}

public struct Instant<Value>: Motion {

    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, _ in
            MotionData(duration: .zero) { _, _ in
                value
            }
        }
    }
}

public struct SideEffect<Value>: Motion {

    public let action: (Value) -> Void
    
    public init(_ action: @escaping () -> Void) {
        self.init { _ in action() }
    }
    
    public init(_ action: @escaping (Value) -> Void) {
        self.action = action
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { value, _ in
            MotionData(duration: .zero) { value, t in
                value
            } sideEffects: { range in
                if range.contains(1.0) {
                    return [action]
                }
                return []
            }
        }
    }
}

public struct Repeat<Value>: Motion {
    public let count: Int
    public let motion: AnyMotion<Value>
    
    public init(_ count: Int, @MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.count = count
        self.motion = motion()
    }
    
    public var anyMotion: AnyMotion<Value> {
        guard count > 0 else {
            return AnyMotion { _, _ in
                MotionData(duration: .zero) { value, _ in value }
            }
        }
        
        guard count > 1 else {
            return motion
        }
        
        return AnyMotion { value, dur in
            let motionData = motion.prepare(value, dur.map { $0 / Double(count) })

            return MotionData(
                duration: motionData.duration.map { $0 * Double(count) },
                lerp: { value, t in
                    // Calculate which repeat and the time within that repeat
                    let repeatT = t == 1.0 ? 1.0 : (t *  Double(count)).truncatingRemainder(dividingBy: 1.0)
                    return motionData.lerp(value, repeatT)
                },
                sideEffects: motionData.sideEffects.map { sideEffects in
                    { range in
                        let start = range.lowerBound * Double(count)
                        let end = range.upperBound * Double(count)
                        
                        // Map to individual repeat ranges
                        var effects: [(Value) -> Void] = []
                        for i in 0..<count {
                            let repeatStart = Double(i)
                            let repeatEnd = Double(i + 1)
                            
                            if start < repeatEnd && end > repeatStart {
                                let segmentStart = max(0, (start - repeatStart))
                                let segmentEnd = min(1, (end - repeatStart))
                                
                                if segmentStart < segmentEnd {
                                    effects.append(contentsOf: sideEffects(segmentStart...segmentEnd))
                                }
                            }
                        }
                        
                        return effects
                    }
                }
            )
        }
    }
}

public struct Sync<Value>: Motion {
    
    let child: AnyMotion<Value>
    
    public init(@MotionBuilder<Value> _ child: () -> AnyMotion<Value>) {
        self.child = child()
    }
    
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { value, dur in
            var result = child.anyMotion.prepare(value, dur)
            if let duration = result.duration?.seconds {
                let lerp = result.lerp
                result.lerp = { value, _ in
                    lerp(value, Date().timeIntervalSince1970.truncatingRemainder(dividingBy: duration))
                }
            }
            return result
        }
    }
}

public struct Steps<Value>: Motion {
    
    public let values: [Value]
    
    public init(_ values: [Value]) {
        self.values = values
    }
    
    public init(_ values: Value...) {
        self.init(values)
    }
    
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            MotionData(duration: dur) { first, t in
                guard !values.isEmpty else { return first }
                
                // Use first value at the beginning
                if t == 0 { return first }
                
                // Use last value at the end
                if t >= 1.0 { return values.last! }
                
                // For intermediate values, calculate the index based on time
                // If we have N values, we have N-1 intervals
                // The index is calculated as floor(t * (values.count))
                let allValues = [first] + values
                let index = min(Int(t * Double(allValues.count)), allValues.count - 1)
                return allValues[index]
            }
        }
    }
}

public struct AutoReverse<Value>: Motion {

    public let motion: AnyMotion<Value>
    
    public init(@MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.motion = motion()
    }

    public var anyMotion: AnyMotion<Value> {
        AnyMotion { value, dur in
            let motionData = motion.prepare(value, dur.map { $0 / 2.0 })
    
            return MotionData(
                duration: motionData.duration.map { $0 * 2 },
                lerp: { value, t in
                    // 0-0.5 is forward, 0.5-1.0 is reverse
                    let adjustedT = t <= 0.5 ? t * 2 : 2.0 - t * 2
                    return motionData.lerp(value, adjustedT)
                },
                sideEffects: motionData.sideEffects.map { sideEffects in
                    { range in
                        let start = range.lowerBound
                        let end = range.upperBound
                        
                        var effects: [(Value) -> Void] = []
                        
                        // Forward part (0-0.5)
                        if start < 0.5 && end > 0 {
                            let forwardStart = max(0, start) * 2
                            let forwardEnd = min(0.5, end) * 2
                            effects.append(contentsOf: sideEffects(forwardStart...forwardEnd))
                        }
                        
                        // Reverse part (0.5-1.0)
                        if start < 1.0 && end > 0.5 {
                            let reverseStart = 2.0 - min(1.0, end) * 2
                            let reverseEnd = 2.0 - max(0.5, start) * 2
                            effects.append(contentsOf: sideEffects(reverseStart...reverseEnd))
                        }
                        
                        return effects
                    }
                }
            )
        }
    }
}

extension Motion {
    
    public func autoreverse() -> AutoReverse<Value> {
        AutoReverse { self }
    }

    public func `repeat`(_ count: Int) -> Repeat<Value> {
        Repeat(count) { self }
    }

    public func duration(_ duration: TimeInterval) -> AnyMotion<Value> {
        AnyMotion { value, _ in
            anyMotion.prepare(value, .absolute(duration))
        }
    }

    public func relativeDuration(_ duration: Double) -> AnyMotion<Value> {
        AnyMotion { value, _ in
            anyMotion.prepare(value, .relative(duration))
        }
    }
    
    public func sync() -> Sync<Value> {
        Sync { self }
    }

    public func curve(_ curve: Curve) -> AnyMotion<Value> {
        AnyMotion { value, duration in
            var result = anyMotion.prepare(value, duration)
            let lerp = result.lerp
            result.lerp = { value, t in
                lerp(value, curve(t))
            }
            return result
        }
    }
}

private func transformEffectT(_ t: Double, _ start: Double, _ end: Double, _ relDur: Double) -> Double {
    if relDur == 0 {
        if t == 0.0 && start == 0.0 { return 0.0 }
        else if t == end { return 1.0 }
        else if end < t { return .infinity }
        else { return -.infinity }
    } else {
        return relDur / (start - t)
    }
}
