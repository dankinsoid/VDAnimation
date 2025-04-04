import SwiftUI

/// Protocol defining a motion animation for a specific value type
///
/// Motion animations describe how values change over time and can be composed
/// together to create complex animations.
///
/// Example:
/// ```swift
/// // Create a simple position animation
/// let positionMotion = To(CGPoint(x: 100, y: 200))
///
/// // Apply the motion with specified duration and curve
/// let animatedPosition = positionMotion
///     .duration(0.5)
///     .curve(.easeInOut)
/// ```
public protocol Motion<Value> {

    /// The type of value being animated
    associatedtype Value

    /// Converts this motion to a type-erased AnyMotion representation
    var anyMotion: AnyMotion<Value> { get }
}

/// Describes the duration of an animation
///
/// Duration can be either absolute (in seconds) or relative 
/// (as a fraction of a parent animation's duration)
public enum Duration {

    /// An absolute duration in seconds
    case absolute(Double)
    
    /// A relative duration (fraction of the parent animation's duration)
    case relative(Double)
    
    /// A duration of zero seconds
    public static let zero = Duration.absolute(0)
    
    /// The duration in seconds if this is an absolute duration, nil otherwise
    public var seconds: Double? {
        if case let .absolute(double) = self {
            return double
        }
        return nil
    }
    
    /// The relative duration value if this is a relative duration, nil otherwise
    public var relative: Double? {
        if case let .relative(double) = self {
            return double
        }
        return nil
    }
    
    /// Divides a duration by a scalar value
    /// - Parameters:
    ///   - lhs: The duration to divide
    ///   - rhs: The scalar divisor
    /// - Returns: A new duration with the value divided by the scalar
    public static func /(_ lhs: Duration, _ rhs: Double) -> Duration {
        switch lhs {
        case .absolute(let double):
            return .absolute(double / rhs)
        case .relative(let double):
            return .relative(double / rhs)
        }
    }

    /// Multiplies a duration by a scalar value
    /// - Parameters:
    ///   - lhs: The duration to multiply
    ///   - rhs: The scalar multiplier
    /// - Returns: A new duration with the value multiplied by the scalar
    public static func *(_ lhs: Duration, _ rhs: Double) -> Duration {
        switch lhs {
        case .absolute(let double):
            return .absolute(double * rhs)
        case .relative(let double):
            return .relative(double * rhs)
        }
    }
}

/// A type-erased motion for animating values of type Value
public struct AnyMotion<Value>: Motion {

    /// Function to prepare motion data based on initial value and duration
    public let prepare: (Value, Duration?) -> MotionData<Value>

    /// Returns self as an AnyMotion since this is already type-erased
    public var anyMotion: AnyMotion<Value> { self }

    public init(prepare: @escaping (Value, Duration?) -> MotionData<Value>) {
        self.prepare = prepare
    }

    public init(@MotionBuilder<Value> _ builder: () -> AnyMotion<Value>) {
        prepare = builder().prepare
    }
}

/// Contains the data needed to perform a motion animation
public struct MotionData<Value> {

    /// The duration of the motion
    public var duration: Duration?
    
    /// Function to interpolate from the initial value to the target value based on time
    public var lerp: (Value, Double) -> Value
    
    /// Optional function to provide side effects at specific points in the animation
    public var sideEffects: ((ClosedRange<Double>) -> [(Value) -> Void])?
    
    /// Creates a new MotionData instance
    /// - Parameters:
    ///   - duration: The duration of the motion
    ///   - lerp: Function to interpolate the value
    ///   - sideEffects: Optional function that provides side effects for a range of progress values
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

/// A motion that starts from a specific value
///
/// `From` sets a specific starting value for an animation, regardless of the
/// current value of the animated property. This is useful when you want to ensure
/// an animation always starts from the same state.
///
/// Example:
/// ```swift
/// // Always start from opacity 0, regardless of current value
/// let fadeIn = From(0.0) {
///     To(1.0).duration(0.3)
/// }
///
/// // Start a position animation from a specific point
/// let moveFrom = From(CGPoint(x: 0, y: 0)) {
///     To(CGPoint(x: 100, y: 100))
/// }
/// ```
public struct From<Value>: Motion {

    /// The starting value for the animation
    public let value: Value
    
    /// The motion to apply starting from the specified value
    public let motion: AnyMotion<Value>

    /// Creates a motion that starts from a specific value
    /// - Parameters:
    ///   - value: The starting value
    ///   - motion: The motion to apply
    public init(_ value: Value, @MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.value = value
        self.motion = motion()
    }

    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            var result = motion.anyMotion.prepare(value, dur)
            let lerp = result.lerp
            result.lerp = { _, t in lerp(value, t) }
            return result
        }
    }
}

/// A motion that runs a sequence of motions one after another
///
/// `Sequential` plays multiple animations in sequence, where each animation starts
/// after the previous one completes. This is ideal for creating multi-step animations
/// where timing and order matter.
///
/// Example:
/// ```swift
/// // Fade in, wait, then move
/// let sequence = Sequential<MyModel> {
///     // First animate opacity from 0 to 1 over 0.3 seconds
///     Parallel { value in
///         value.opacity(To(1.0).duration(0.3))
///     }
///     
///     // Then wait for 0.5 seconds
///     Wait(Duration.absolute(0.5))
///     
///     // Finally move to a new position over 0.7 seconds
///     Parallel { value in
///         value.position(To(CGPoint(x: 200, y: 200)).duration(0.7))
///     }
/// }
/// ```
public struct Sequential<Value>: Motion {
    
    /// Function that provides an array of motions to run in sequence
    public let motions: () -> [AnyMotion<Value>]
    
    /// Creates a sequential motion from an array of motions
    /// - Parameter motions: The motions to run in sequence
    public init(@MotionsArrayBuilder<Value> _ motions: @escaping () -> [AnyMotion<Value>]) {
        self.motions = motions
    }
    
    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { initialValue, expDur in
            // Accumulation state structure
            
            // Reduce over all motions to prepare them
            var state = MotionState(lastValue: initialValue)
            
            for motion in motions() {
                var info = motion.prepare(state.lastValue, nil)
                let nextValue = info.lerp(state.lastValue, 1.0)
                let duration = info.duration?.seconds
                let relative = (info.duration?.relative).map(clamp)
                info.duration = relative.map(Duration.relative) ?? info.duration
                
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
                    relDur = relativeDuration * relK
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
    
    /// Clamps a value between 0.0 and 1.0
    func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
    
    /// Internal state for processing sequential motions
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

    /// Internal representation of a motion item with timing information
    private struct Item {
        var data: MotionData<Value>
        var start: Double = 0.0
        var end: Double = 0.0
        var relDur: Double = 0.0
    }
}

/// A motion that runs multiple animations in parallel
///
/// `Parallel` runs multiple animations simultaneously, allowing you to animate different
/// properties of an object at the same time. Animations can have different durations
/// and curves but will start together.
///
/// Example:
/// ```swift
/// // Animate multiple properties simultaneously
/// let animation = Parallel<MyView> {
///     // Use dynamic member lookup for properties
///     $0.opacity(To(1.0).duration(0.5))
///     $0.scale(To(1.2).duration(0.3).curve(.easeOut))
///     $0.position(To(CGPoint(x: 100, y: 200)).duration(0.8))
/// }
///
/// // Alternative syntax using keypath
/// let animation2 = Parallel<MyView>()
///     .at(\.opacity, { To(1.0) })
///     .at(\.position, { To(CGPoint(x: 100, y: 200)) })
/// ```
@dynamicMemberLookup
public struct Parallel<Value>: Motion {
    
    /// Function that generates motions to run in parallel for a given value
    private var motions: (Value) -> [AnyMotion<Value>]
    
    /// Internal representation of a motion item
    private struct Item {
        let data: MotionData<Value>
        var relative: Double
    }
    
    /// Creates an empty parallel motion
    public init() {
        self.motions = { _ in [] }
    }
    
    /// Creates a parallel motion that animates multiple children of a value
    /// - Parameters:
    ///   - children: Function that provides child motions with identifiers
    ///   - getter: Function to extract a child value using its identifier
    ///   - setter: Function to update a child value using its identifier
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
                        duration: data.duration,
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

    /// Converts to a type-erased motion
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

    /// Adds a motion for a specific key path
    /// - Parameters:
    ///   - keyPath: The key path to animate
    ///   - motion: The motion to apply to the key path
    /// - Returns: A new parallel motion with the added animation
    public func at<Child>(_ keyPath: WritableKeyPath<Value, Child>, @MotionBuilder<Child> _ motion: @escaping () -> AnyMotion<Child>) -> Parallel {
        var result = self
        let motions = result.motions
        result.motions = { motions($0) + Parallel(keyPath, motion).motions($0) }
        return result
    }

    /// Dynamic member lookup for creating animations for specific properties
    /// - Parameter keyPath: The key path to animate
    /// - Returns: A path object for further configuration
    public subscript<Child>(dynamicMember keyPath: WritableKeyPath<Value, Child>) -> Path<Child> {
        Path<Child>(base: self, keyPath: keyPath)
    }

    /// Helper struct for creating animations for a specific path
    @dynamicMemberLookup
    public struct Path<Child> {

        let base: Parallel<Value>
        let keyPath: WritableKeyPath<Value, Child>

        /// Applies a motion to this path
        /// - Parameter value: The motion to apply
        /// - Returns: A parallel motion with the animation added
        public func callAsFunction(@MotionBuilder<Child> _ value: @escaping () -> AnyMotion<Child>) -> Parallel {
            var result = base
            let motions = result.motions
            result.motions = { motions($0) + Parallel(keyPath, value).motions($0) }
            return result
        }

        public func callAsFunction(_ value: Child, _ rest: Child..., lerp: @escaping (Child, Child, Double) -> Child) -> Parallel {
            callAsFunction {
                To([value] + rest, lerp: lerp)
            }
        }

        public func callAsFunction(_ value: Child, _ rest: Child...) -> Parallel where Child: Tweenable {
            callAsFunction {
                To([value] + rest)
            }
        }

        /// Dynamic member lookup for creating animations for specific properties
        /// - Parameter keyPath: The key path to animate
        /// - Returns: A path object for further configuration
        public subscript<T>(dynamicMember keyPath: WritableKeyPath<Child, T>) -> Path<T> {
            Path<T>(base: base, keyPath: self.keyPath.appending(path: keyPath))
        }
    }
}

extension Parallel {

    /// Creates a parallel motion that animates a single property
    /// - Parameters:
    ///   - keyPath: The key path to the property to animate
    ///   - motion: The motion to apply to the property
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

    /// Creates a parallel motion that animates dictionary values
    /// - Parameter motion: A function that provides a motion for each dictionary key
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
    /// Creates a parallel motion that animates collection elements
    /// - Parameter motion: A function that provides a motion for each collection index
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

/// A motion that animates toward one or more target values
///
/// `To` animates from the current value to a target value or through a series of values.
/// When multiple values are provided, the animation will move through each value in sequence.
///
/// Example:
/// ```swift
/// // Simple animation to a single value
/// let fadeIn = To(1.0)  // Animate opacity to 1.0
///
/// // Animation through multiple points
/// let complexPath = To(
///     CGPoint(x: 50, y: 50),
///     CGPoint(x: 100, y: 0),
///     CGPoint(x: 150, y: 50)
/// )
///
/// // With duration and curve
/// let smooth = To(1.0)
///     .duration(0.5)
///     .curve(.easeInOut)
/// ```
public struct To<Value>: Motion {

    /// The target values to animate toward
    public let values: [Value]
    
    /// The interpolation function to use
    public let lerp: (Value, Value, Double) -> Value

    /// Creates a "to" motion with a custom interpolation function
    /// - Parameters:
    ///   - values: The target values to animate toward
    ///   - lerp: The interpolation function to use
    public init(_ values: [Value], lerp: @escaping (Value, Value, Double) -> Value) {
        self.values = values
        self.lerp = lerp
    }

    /// Creates a "to" motion with a custom interpolation function and variadic values
    /// - Parameters:
    ///   - values: The target values to animate toward
    ///   - lerp: The interpolation function to use
    public init(_ values: Value..., lerp: @escaping (Value, Value, Double) -> Value) {
        self.init(values, lerp: lerp)
    }

    /// Converts to a type-erased motion
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
                
                // Lerp between the values in this segment
                return lerp(allValues[segment], allValues[nextSegment], segmentT)
            }
        }
    }
}

extension To where Value: Tweenable {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ values: [Value]) {
        self.init(values, lerp: Value.lerp)
    }

    /// Creates a "to" motion using the default lerp function and variadic values
    /// - Parameter values: The target values to animate toward
    public init(_ value: Value, _ rest: Value...) {
        self.init([value] + rest, lerp: Value.lerp)
    }
}

extension To where Value: Tweenable & VectorArithmetic {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ values: [Value]) {
        self.init(values, lerp: Value.lerp)
    }

    /// Creates a "to" motion using the default lerp function and variadic values
    /// - Parameter values: The target values to animate toward
    public init(_ value: Value, _ rest: Value...) {
        self.init([value] + rest, lerp: Value.lerp)
    }
}

extension To where Value: VectorArithmetic {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ values: [Value]) {
        self.init(values) {
            $0.interpolated(towards: $1, amount: $2)
        }
    }

    /// Creates a "to" motion using the default lerp function and variadic values
    /// - Parameter values: The target values to animate toward
    public init(_ value: Value, _ rest: Value...) {
        self.init([value] + rest) {
            $0.interpolated(towards: $1, amount: $2)
        }
    }
}

extension To where Value: Codable {

    /// Creates a "to" motion for Codable values
    /// - Parameter values: The target values to animate toward
    @_disfavoredOverload
    public init(_ values: [Value]) {
        self.init(values, lerp: Value.lerp)
    }

    /// Creates a "to" motion for Codable values with variadic syntax
    /// - Parameter values: The target values to animate toward
    @_disfavoredOverload
    public init(_ values: Value...) {
        self.init(values, lerp: Value.lerp)
    }
}

public struct Lerp<Value>: Motion {

    public let lerp: (Value, Double) -> Value

    public init(lerp: @escaping (Value, Double) -> Value) {
        self.lerp = lerp
    }

    public init(lerp: @escaping (Double) -> Value) {
        self.init { _, t in lerp(t) }
    }

    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            MotionData(duration: dur, lerp: lerp)
        }
    }
}

public struct TransformTo<Value>: Motion {

    /// The target values to animate toward
    public let transform: (Value) -> Value

    /// The interpolation function to use
    public let lerp: (Value, Value, Double) -> Value

    /// Creates a "to" motion with a custom interpolation function
    /// - Parameters:
    ///   - transform: The target values to animate toward
    ///   - lerp: The interpolation function to use
    public init(_ transform: @escaping (Value) -> Value, lerp: @escaping (Value, Value, Double) -> Value) {
        self.transform = transform
        self.lerp = lerp
    }

    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            return MotionData(duration: dur) { first, t in
                let value = transform(first)
                guard t != 0 else { return first }
                guard t != 1 else { return value }
                // Lerp between the values in this segment
                return lerp(first, value, t)
            }
        }
    }
}

extension TransformTo where Value: Tweenable {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ transform: @escaping (Value) -> Value) {
        self.init(transform, lerp: Value.lerp)
    }
}

extension TransformTo where Value: VectorArithmetic {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ transform: @escaping (Value) -> Value) {
        self.init(transform) {
            $0.interpolated(towards: $1, amount: $2)
        }
    }
}

extension TransformTo where Value: Tweenable & VectorArithmetic {

    /// Creates a "to" motion using the default lerp function
    /// - Parameter values: The target values to animate toward
    public init(_ transform: @escaping (Value) -> Value) {
        self.init(transform, lerp: Value.lerp)
    }
}

extension TransformTo where Value: Codable {

    /// Creates a "to" motion for Codable values
    /// - Parameter values: The target values to animate toward
    @_disfavoredOverload
    public init(_ transform: @escaping (Value) -> Value) {
        self.init(transform, lerp: Value.lerp)
    }
}

/// A motion that pauses for a specified duration
///
/// `Wait` creates a pause in an animation sequence, holding the current value
/// for the specified duration before continuing to the next motion.
///
/// Example:
/// ```swift
/// // Create a sequence with a pause
/// let animation = Sequential<CGFloat> {
///     To(1.0).duration(0.3)  // Animate to 1.0
///     Wait(Duration.absolute(0.5))  // Wait for half a second
///     To(0.0).duration(0.3)  // Animate back to 0.0
/// }
///
/// // Wait with relative duration
/// let relativeWait = Sequential<CGFloat> {
///     To(1.0)
///     Wait(.relative(0.25))  // Wait for 25% of the parent duration
///     To(0.0)
/// }
/// ```
public struct Wait<Value>: Motion {

    /// The duration to wait
    public let duration: Duration?

    /// Creates a wait motion
    /// - Parameter duration: The duration to wait (defaults to inheriting from parent)
    public init(_ duration: Duration? = nil) {
        self.duration = duration
    }

    /// Creates a wait motion
    /// - Parameter duration: The duration to wait (defaults to inheriting from parent)
    public init(_ duration: Double) {
        self.init(.absolute(duration))
    }

    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, dur in
            MotionData(duration: duration ?? dur) { value, _ in
                value
            }
        }
    }
}

/// A motion that instantly changes to a specific value
///
/// `Instant` immediately changes a value without any animation. This is useful
/// for creating sudden changes within a sequence of animations.
///
/// Example:
/// ```swift
/// // Sequence with an instant change
/// let animation = Sequential<Double> {
///     To(0.5).duration(0.3)  // Animate to 0.5
///     Instant(1.0)  // Instantly jump to 1.0
///     To(0.0).duration(0.3)  // Animate back to 0.0
/// }
///
/// // Reset position instantly, then animate size
/// let complexAnimation = Sequential<MyView> {
///     Parallel {
///         $0.position(Instant(CGPoint.zero))
///     }
///     Parallel {
///         $0.size(To(CGSize(width: 200, height: 200)).duration(0.5))
///     }
/// }
/// ```
public struct Instant<Value>: Motion {

    /// The value to change to
    public let value: Value

    /// Creates an instant motion
    /// - Parameter value: The value to change to
    public init(_ value: Value) {
        self.value = value
    }

    /// Converts to a type-erased motion
    public var anyMotion: AnyMotion<Value> {
        AnyMotion { _, _ in
            MotionData(duration: .zero) { _, _ in
                value
            }
        }
    }
}

/// A motion that performs a side effect at a specific point in the animation
///
/// `SideEffect` executes a closure at a specific point in the animation sequence,
/// allowing you to trigger sound effects, haptic feedback, or other actions that
/// should occur during animation.
///
/// Example:
/// ```swift
/// // Play a sound after fading in
/// let animation = Sequential<Double> {
///     To(1.0).duration(0.3)  // Fade in
///     SideEffect {
///         playSound("complete.wav")
///     }
///     Wait(Duration.absolute(0.1))
///     To(0.8).duration(0.1)  // Slight fade out
/// }
///
/// // Access the current value in the side effect
/// let valueAwareEffect = Sequential<MyModel> {
///     To(someValue).duration(0.5)
///     SideEffect { value in
///         print("Animation completed with value: \(value)")
///         updateUI(with: value)
///     }
/// }
/// ```
public struct SideEffect<Value>: Motion {

    /// The action to perform
    public let action: (Value) -> Void
    
    /// Creates a side effect motion with a simple action
    /// - Parameter action: The action to perform
    public init(_ action: @escaping () -> Void) {
        self.init { _ in action() }
    }
    
    /// Creates a side effect motion with an action that receives the current value
    /// - Parameter action: The action to perform
    public init(_ action: @escaping (Value) -> Void) {
        self.action = action
    }

    /// Converts to a type-erased motion
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

/// A motion that repeats another motion a specified number of times
///
/// `Repeat` runs an animation multiple times in sequence. The total duration
/// is divided equally among all repetitions.
///
/// Example:
/// ```swift
/// // Pulse an element 3 times
/// let pulse = Repeat(3) {
///     Sequential {
///         To(1.2).duration(0.15)  // Scale up
///         To(0.9).duration(0.15)  // Scale down
///     }
/// }
///
/// // Repeat a complex animation
/// let complexRepeat = Repeat(5) {
///     Sequential {
///         To(1.0).duration(0.2)
///         To(0.5).duration(0.1)
///         To(0.8).duration(0.1)
///     }
/// }.duration(2.0)  // Total duration for all repetitions
/// ```
public struct Repeat<Value>: Motion {
    /// The number of times to repeat the motion
    public let count: Int
    
    /// The motion to repeat
    public let motion: AnyMotion<Value>
    
    /// Creates a repeat motion
    /// - Parameters:
    ///   - count: The number of times to repeat
    ///   - motion: The motion to repeat
    public init(_ count: Int, @MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.count = count
        self.motion = motion()
    }
    
    /// Converts to a type-erased motion
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

/// A motion that synchronizes to the current time
///
/// `Sync` creates an animation that continuously runs based on the current time
/// rather than a specific start time. This is useful for creating ongoing animations
/// that should always be in sync with the system clock.
///
/// Example:
/// ```swift
/// // Create a continuous pulsing effect
/// let continuousPulse = Sync {
///     To(1.2, 0.8, 1.0).duration(2.0).curve(.easeInOut)
/// }
///
/// // Synchronize a rotation animation with time
/// let spinner = Sync {
///     To(CGFloat.pi * 2).duration(1.0)
/// }
/// ```
public struct Sync<Value>: Motion {
    
    /// The child motion to synchronize
    let child: AnyMotion<Value>
    
    /// Creates a synchronized motion
    /// - Parameter child: The motion to synchronize
    public init(@MotionBuilder<Value> _ child: () -> AnyMotion<Value>) {
        self.child = child()
    }
    
    /// Converts to a type-erased motion
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

/// A motion that steps through discrete values
///
/// `Steps` animates through a series of values with discrete jumps rather than
/// smooth interpolation. The animation time is divided equally among the steps.
///
/// Example:
/// ```swift
/// // Animate through distinct opacity values
/// let opacitySteps = Steps(0.0, 0.3, 0.7, 1.0)
///     .duration(1.0)
///
/// // Create a step-based position animation
/// let jumpyPath = Steps(
///     CGPoint(x: 0, y: 0),
///     CGPoint(x: 100, y: 0),
///     CGPoint(x: 100, y: 100),
///     CGPoint(x: 0, y: 100)
/// ).duration(2.0)
/// ```
public struct Steps<Value>: Motion {
    
    /// The values to step through
    public let values: [Value]
    
    /// Creates a steps motion with an array of values
    /// - Parameter values: The values to step through
    public init(_ values: [Value]) {
        self.values = values
    }
    
    /// Creates a steps motion with variadic values
    /// - Parameter values: The values to step through
    public init(_ values: Value...) {
        self.init(values)
    }
    
    /// Converts to a type-erased motion
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

/// A motion that plays forward then reverses
///
/// `AutoReverse` runs an animation forward then backward, creating a ping-pong effect.
/// The total duration is divided equally between the forward and reverse phases.
///
/// Example:
/// ```swift
/// // Create a bounce effect
/// let bounce = AutoReverse {
///     To(1.2).duration(0.5).curve(.easeOut)
/// }
///
/// // Fade in and out
/// let pulse = AutoReverse {
///     To(1.0).duration(0.5).curve(.easeInOut)
/// }.duration(1.2)  // Total time for both directions
///
/// // Alternative usage with method syntax
/// let pulse2 = To(1.0).duration(0.5).curve(.easeInOut).autoreverse()
/// ```
public struct AutoReverse<Value>: Motion {

    /// The motion to auto-reverse
    public let motion: AnyMotion<Value>
    
    /// Creates an auto-reverse motion
    /// - Parameter motion: The motion to play forward and then reverse
    public init(@MotionBuilder<Value> _ motion: () -> AnyMotion<Value>) {
        self.motion = motion()
    }

    /// Converts to a type-erased motion
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
    
    /// Creates an auto-reverse motion that plays this motion forward then in reverse
    /// - Returns: An auto-reverse motion
    public func autoreverse() -> AutoReverse<Value> {
        AutoReverse { self }
    }

    /// Repeats this motion a specified number of times
    /// - Parameter count: The number of times to repeat
    /// - Returns: A repeat motion
    public func `repeat`(_ count: Int) -> Repeat<Value> {
        Repeat(count) { self }
    }

    /// Sets an absolute duration for this motion
    /// - Parameter duration: The duration in seconds
    /// - Returns: A type-erased motion with the specified duration
    public func duration(_ duration: TimeInterval) -> AnyMotion<Value> {
        self.duration(.absolute(duration))
    }

    /// Sets an absolute duration for this motion
    /// - Parameter duration: The duration.
    /// - Returns: A type-erased motion with the specified duration
    public func duration(_ duration: Duration) -> AnyMotion<Value> {
        AnyMotion { value, _ in
            anyMotion.prepare(value, duration)
        }
    }
    
    /// Sets an absolute delay for this motion
    /// - Parameter delay: The delay in seconds
    /// - Returns: A type-erased motion with the specified duration
    @MotionBuilder<Value>
    public func delay(_ delay: TimeInterval) -> AnyMotion<Value> {
        self.delay(.absolute(delay))
    }

    /// Sets an absolute delay for this motion
    /// - Parameter delay: The delay.
    /// - Returns: A type-erased motion with the specified duration
    @MotionBuilder<Value>
    public func delay(_ delay: Duration) -> AnyMotion<Value> {
        Sequential {
            Wait(delay)
            self
        }
    }

    /// Synchronizes this motion with the current time
    ///
    /// This method creates a motion that continuously runs based on the current time
    /// rather than a specific start time. This is useful for creating ongoing animations
    /// that should always be in sync with the system clock such as a spinner.
    ///
    /// - Returns: A synchronized motion
    public func sync() -> Sync<Value> {
        Sync { self }
    }

    /// Applies an animation curve to this motion
    /// - Parameter curve: The animation curve to apply
    /// - Returns: A type-erased motion with the curve applied
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

extension Tween: Motion where Bound: Tweenable {

    public var anyMotion: AnyMotion<Bound> {
        AnyMotion { _, duration in
            MotionData(duration: duration, lerp: { _, t in lerp(t) })
        }
    }
}

/// Transforms a time value for side effects based on the motion's timing parameters
/// - Parameters:
///   - t: The original time value
///   - start: The start time of the motion
///   - end: The end time of the motion
///   - relDur: The relative duration of the motion
/// - Returns: The transformed time value
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
