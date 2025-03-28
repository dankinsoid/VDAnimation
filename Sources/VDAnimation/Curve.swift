import Foundation

/// A structure that represents an animation curve.
/// 
/// Use this to create custom interpolation functions for animations.
public struct Curve {
    
    /// The function that calculates the interpolated value.
    ///
    /// - Parameter t: A value between 0 and 1 representing animation progress.
    /// - Returns: The interpolated value based on the curve.
    public let interpolate: (_ t: Double) -> Double
    
    /// Creates a new curve with the given interpolation function.
    ///
    /// - Parameter interpolate: A function that takes a value between 0 and 1 and returns an interpolated value.
    public init(_ interpolate: @escaping (_: Double) -> Double) {
        self.interpolate = interpolate
    }
    
    /// Calls the curve's interpolation function with the given value.
    ///
    /// - Parameter t: A value between 0 and 1 representing animation progress.
    /// - Returns: The interpolated value based on the curve.
    public func callAsFunction(_ t: Double) -> Double {
        interpolate(t)
    }
}

public extension Curve {

    /// A linear interpolation curve that progresses at a constant rate.
    static let linear = Curve { $0 }
    
    /// A quadratic ease-in curve that starts slowly and accelerates.
    static let easeIn = Curve { $0 * $0 }
    
    /// A quadratic ease-out curve that starts quickly and decelerates.
    static let easeOut = Curve { 1.0 - (1.0 - $0) * (1.0 - $0) }
    
    /// A quadratic ease-in-out curve that starts slowly, accelerates in the middle, and decelerates at the end.
    static let easeInOut = Curve { $0 < 0.5 ? 2.0 * $0 * $0 : 1.0 - pow(-2.0 * $0 + 2.0, 2) / 2.0 }
    
    /// A cubic ease-in curve that starts slowly and accelerates more dramatically than quadratic.
    static let cubicEaseIn = Curve { $0 * $0 * $0 }
    
    /// A cubic ease-out curve that starts quickly and decelerates more dramatically than quadratic.
    static let cubicEaseOut = Curve { 1.0 - pow(1.0 - $0, 3) }
    
    /// A cubic ease-in-out curve that provides a stronger acceleration and deceleration than quadratic.
    static let cubicEaseInOut = Curve { $0 < 0.5 ? 4.0 * $0 * $0 * $0 : 1.0 - pow(-2.0 * $0 + 2.0, 3) / 2.0 }
    
    /// An elastic ease-in curve that simulates an elastic band being pulled and released.
    static let elasticEaseIn = Curve {
        if $0 == 0 { return 0 }
        if $0 == 1 { return 1 }
        return -pow(2, 10 * $0 - 10) * sin(($0 * 10 - 10.75) * Double.pi * 2 / 3)
    }
    
    /// An elastic ease-out curve that overshoots the target and then settles.
    static let elasticEaseOut = Curve {
        if $0 == 0 { return 0 }
        if $0 == 1 { return 1 }
        return pow(2, -10 * $0) * sin(($0 * 10 - 0.75) * Double.pi * 2 / 3) + 1
    }
    
    /// A bounce ease-out curve that simulates a bouncing effect at the end.
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
    
    /// A bounce ease-in curve that simulates a bouncing effect at the beginning.
    static let bounceEaseIn = Curve { 1.0 - bounceEaseOut(1.0 - $0) }
    
    /// A sine-based ease-in curve that accelerates using a sine function.
    static let sineEaseIn = Curve { 1.0 - cos($0 * Double.pi / 2) }
    
    /// A sine-based ease-out curve that decelerates using a sine function.
    static let sineEaseOut = Curve { sin($0 * Double.pi / 2) }
    
    /// A sine-based ease-in-out curve that uses a sine function for both acceleration and deceleration.
    static let sineEaseInOut = Curve { -(cos(Double.pi * $0) - 1) / 2 }
    
    /// A back ease-in curve that slightly overshoots in the opposite direction before moving toward the target.
    static let backEaseIn = Curve {
        let c1 = 1.70158
        let c3 = c1 + 1
        return c3 * $0 * $0 * $0 - c1 * $0 * $0
    }
    
    /// A back ease-out curve that overshoots the target and then returns to it.
    static let backEaseOut = Curve {
        let c1 = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow($0 - 1, 3) + c1 * pow($0 - 1, 2)
    }

    /// Creates a step function that jumps from 0 to 1 at the specified threshold.
    ///
    /// - Parameter threshold: The point at which the value jumps from 0 to 1, default is 0.5.
    /// - Returns: A step curve.
    static func step(threshold: Double = 0.5) -> Curve {
        Curve { $0 >= threshold ? 1.0 : 0.0 }
    }

    /// Creates a linear curve that maps 0-1 to the specified interval.
    ///
    /// - Parameter range: The range to map the animation progress to.
    /// - Returns: A curve that progresses linearly within the specified range.
    static func interval(_ range: ClosedRange<Double>) -> Curve {
        Curve { t in
            if t <= range.lowerBound { return 0.0 }
            if t >= range.upperBound || range.lowerBound == range.upperBound { return 1.0 }
            return (t - range.lowerBound) / (range.upperBound  - range.lowerBound)
        }
    }

    /// Creates a spring curve with the specified parameters.
    ///
    /// - Parameters:
    ///   - damping: The damping ratio of the spring, default is 0.5.
    ///   - velocity: The initial velocity of the spring, default is 16.0.
    /// - Returns: A spring curve.
    static func spring(damping: Double = 0.5, velocity: Double = 16.0) -> Curve {
        Curve { t in
            let b = damping
            let v = velocity
            let t2 = t * t
            return 1.0 - (exp(-t * v) * (cos(t2 * v) + (b / v) * sin(t2 * v)))
        }
    }
    
    /// Returns a new curve that is the reverse of this curve.
    ///
    /// - Returns: A curve that progresses in the opposite direction.
    func reversed() -> Curve {
        Curve { 1.0 - self(1.0 - $0) }
    }
    
    /// Returns a new curve that scales the output values by the specified factor.
    ///
    /// - Parameter factor: The factor to scale the curve's output by.
    /// - Returns: A scaled curve.
    func scaled(by factor: Double) -> Curve {
        Curve { self($0) * factor }
    }
    
    /// Returns a new curve with the output values clamped between the specified range.
    ///
    /// - Parameters:
    ///   - minValue: The minimum value to clamp to, default is 0.0.
    ///   - maxValue: The maximum value to clamp to, default is 1.0.
    /// - Returns: A clamped curve.
    func clamped(min minValue: Double = 0.0, max maxValue: Double = 1.0) -> Curve {
        Curve { max(minValue, min(maxValue, self($0))) }
    }

    /// Multiplies the output values of two curves.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side curve.
    ///   - rhs: The right-hand side curve.
    /// - Returns: A curve whose output is the product of the two input curves.
    static func * (lhs: Curve, rhs: Curve) -> Curve {
        Curve { lhs($0) * rhs($0) }
    }

    /// Adds the output values of two curves.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side curve.
    ///   - rhs: The right-hand side curve.
    /// - Returns: A curve whose output is the sum of the two input curves.
    static func + (lhs: Curve, rhs: Curve) -> Curve {
        Curve { lhs($0) + rhs($0) }
    }
}
