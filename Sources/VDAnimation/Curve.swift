import Foundation

public struct Curve {
    
    public let interpolate: (_ t: Double) -> Double
    
    public init(_ interpolate: @escaping (_: Double) -> Double) {
        self.interpolate = interpolate
    }
    
    public func callAsFunction(_ t: Double) -> Double {
        interpolate(t)
    }
}

public extension Curve {

    // Basic curves
    static let linear = Curve { $0 }
    static let easeIn = Curve { $0 * $0 }
    static let easeOut = Curve { 1.0 - (1.0 - $0) * (1.0 - $0) }
    static let easeInOut = Curve { $0 < 0.5 ? 2.0 * $0 * $0 : 1.0 - pow(-2.0 * $0 + 2.0, 2) / 2.0 }
    
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

    // Utility functions
    static func step(threshold: Double = 0.5) -> Curve {
        Curve { $0 >= threshold ? 1.0 : 0.0 }
    }

    static func interval(_ range: ClosedRange<Double>) -> Curve {
        Curve { t in
            if t <= range.lowerBound { return 0.0 }
            if t >= range.upperBound || range.lowerBound == range.upperBound { return 1.0 }
            return (t - range.lowerBound) / (range.upperBound  - range.lowerBound)
        }
    }

    static func spring(damping: Double = 0.5, velocity: Double = 16.0) -> Curve {
        Curve { t in
            let b = damping
            let v = velocity
            let t2 = t * t
            return 1.0 - (exp(-t * v) * (cos(t2 * v) + (b / v) * sin(t2 * v)))
        }
    }
    
    // Composition functions
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
