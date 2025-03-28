import Foundation

/// Represents an animation curve (timing function) that transforms linear progress
///
/// Animation curves change the rate at which an animation progresses, creating
/// effects like acceleration, deceleration, bouncing, etc.
///
/// Example:
/// ```swift
/// // Using standard curves
/// let animation = To(1.0)
///     .duration(0.5)
///     .curve(.easeInOut)
///
/// // Creating a custom curve
/// let customCurve = Curve { t in
///     // Provide your own timing function
///     return sin(t * .pi / 2)
/// }
///
/// let customAnimation = To(targetValue)
///     .curve(customCurve)
/// ```
public struct Curve {
    /// The timing function that transforms linear progress
    let timingFunction: (Double) -> Double
    
    /// Creates a custom animation curve
    /// - Parameter timingFunction: The timing function that transforms linear progress
    public init(_ timingFunction: @escaping (Double) -> Double) {
        self.timingFunction = timingFunction
    }
    
    /// Standard ease-in animation curve (slow start, fast end)
    public static let easeIn = Curve { t in
        t * t * t
    }
    
    /// Standard ease-out animation curve (fast start, slow end)
    public static let easeOut = Curve { t in
        let t1 = t - 1
        return t1 * t1 * t1 + 1
    }
    
    /// Standard ease-in-out animation curve (slow start, slow end, fast middle)
    public static let easeInOut = Curve { t in
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let t1 = 2 * t - 2
            return 0.5 * t1 * t1 * t1 + 1
        }
    }
    
    /// Linear animation curve (constant rate of change)
    public static let linear = Curve { $0 }
    
    /// Applies the timing function to a progress value
    /// - Parameter progress: The linear progress value (0.0-1.0)
    /// - Returns: The adjusted progress value
    public func callAsFunction(_ progress: Double) -> Double {
        // Ensure the input is clamped between 0 and 1
        let clampedProgress = max(0, min(1, progress))
        return timingFunction(clampedProgress)
    }
}

public extension Curve {

    // Cubic curves
    static let cubicEaseIn = Curve { $0 * $0 * $0 }
    static let cubicEaseOut = Curve { 1.0 - pow(1.0 - $0, 3) }
    static let cubicEaseInOut = Curve { $0 < 0.5 ? 4.0 * $0 * $0 * $0 : 1.0 - pow(-2.0 * $0 + 2.0, 3) / 2.0 }
    
    // Elastic curves
    static let elasticEaseIn = Curve {
        if $0 == 0 { return 0 }
        if $0 == 1 { return 1 }
        return -pow(2, 10 * $0 - 10) * sin(($0 * 10 - 10.75) * Double.pi * 2 / 3)
    }
    static let elasticEaseOut = Curve {
        if $0 == 0 { return 0 }
        if $0 == 1 { return 1 }
        return pow(2, -10 * $0) * sin(($0 * 10 - 0.75) * Double.pi * 2 / 3) + 1
    }
    
    // Bounce curves
    static let bounceEaseOut = Curve { t in
        let n1 = 7.5625
        let d1 = 2.75
        var t = t
        
        if t < 1 / d1 {
            return n1 * t * t
        } else if t < 2 / d1 {
            t -= 1.5 / d1
            return n1 * t * t + 0.75
        } else if t < 2.5 / d1 {
            t -= 2.25 / d1
            return n1 * t * t + 0.9375
        } else {
            t -= 2.625 / d1
            return n1 * t * t + 0.984375
        }
    }
    static let bounceEaseIn = Curve { 1.0 - bounceEaseOut(1.0 - $0) }
    
    // Sine curves
    static let sineEaseIn = Curve { 1.0 - cos($0 * Double.pi / 2) }
    static let sineEaseOut = Curve { sin($0 * Double.pi / 2) }
    static let sineEaseInOut = Curve { -(cos(Double.pi * $0) - 1) / 2 }
    
    // Back curves (with overshoot)
    static let backEaseIn = Curve {
        let c1 = 1.70158
        let c3 = c1 + 1
        return c3 * $0 * $0 * $0 - c1 * $0 * $0
    }
    static let backEaseOut = Curve {
        let c1 = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow($0 - 1, 3) + c1 * pow($0 - 1, 2)
    }

    /// Creates a step-based animation curve
    ///
    /// Step animations immediately jump to the end value when a threshold is crossed.
    ///
    /// Example:
    /// ```swift
    /// // Jump to final value at the 75% mark
    /// let lateStep = Curve.step(threshold: 0.75)
    /// ```
    /// - Parameter threshold: The point at which to jump from 0 to 1 (default: 0.5)
    /// - Returns: A step curve
    static func step(threshold: Double = 0.5) -> Curve {
        Curve { $0 >= threshold ? 1.0 : 0.0 }
    }

    /// Creates a curve that's only active within a specific interval
    ///
    /// Example:
    /// ```swift
    /// // Animation only happens between 30% and 70% of the time
    /// let middleAnimation = Curve.interval(0.3...0.7)
    /// ```
    /// - Parameter range: The range where animation occurs (0.0...1.0)
    /// - Returns: An interval curve
    static func interval(_ range: ClosedRange<Double>) -> Curve {
        Curve { t in
            if t <= range.lowerBound { return 0.0 }
            if t >= range.upperBound || range.lowerBound == range.upperBound { return 1.0 }
            return (t - range.lowerBound) / (range.upperBound  - range.lowerBound)
        }
    }

    /// Creates a spring animation curve
    ///
    /// Example:
    /// ```swift
    /// // Create a spring with medium damping and high velocity
    /// let bouncySpring = Curve.spring(damping: 0.4, velocity: 20.0)
    /// ```
    /// - Parameters:
    ///   - damping: How quickly the spring stops (0-1)
    ///   - velocity: The initial velocity of the spring
    /// - Returns: A spring curve
    static func spring(damping: Double = 0.5, velocity: Double = 16.0) -> Curve {
        Curve { t in
            let b = damping
            let v = velocity
            let t2 = t * t
            return 1.0 - (exp(-t * v) * (cos(t2 * v) + (b / v) * sin(t2 * v)))
        }
    }
    
    /// Creates a reversed version of this curve
    ///
    /// Example:
    /// ```swift
    /// // Create the opposite of easeIn (starts fast, ends slow)
    /// let customEaseOut = Curve.easeIn.reversed()
    /// ```
    /// - Returns: A reversed animation curve
    func reversed() -> Curve {
        Curve { 1.0 - self(1.0 - $0) }
    }
    
    func scaled(by factor: Double) -> Curve {
        Curve { self($0) * factor }
    }
    
    func clamped(min minValue: Double = 0.0, max maxValue: Double = 1.0) -> Curve {
        Curve { max(minValue, min(maxValue, self($0))) }
    }

    static func * (lhs: Curve, rhs: Curve) -> Curve {
        Curve { lhs($0) * rhs($0) }
    }

    static func + (lhs: Curve, rhs: Curve) -> Curve {
        Curve { lhs($0) + rhs($0) }
    }
}
