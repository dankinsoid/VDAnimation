import SwiftUI

/// Protocol defining values that can be interpolated (tweened) between two states
/// 
/// Conforming types must implement a `lerp` method that performs linear interpolation
/// between two values using a factor `t` (between 0.0 and 1.0).
public protocol Tweenable {
    
    /// Linearly interpolates between two values of the same type
    /// - Parameters:
    ///   - lhs: Starting value when t=0
    ///   - rhs: Ending value when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: An interpolated value
    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self
}

/// Default Tweenable implementation for floating point types
public extension Tweenable where Self: BinaryFloatingPoint {

    /// Linearly interpolates between two floating point values
    /// - Parameters:
    ///   - lhs: Starting value when t=0
    ///   - rhs: Ending value when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: An interpolated value
    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs }
}

/// Default Tweenable implementation for integer types
extension Tweenable where Self: BinaryInteger {

    /// Linearly interpolates between two integer values
    /// - Parameters:
    ///   - lhs: Starting value when t=0
    ///   - rhs: Ending value when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: An interpolated value (rounded to nearest integer)
    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs }
}

/// Default Tweenable implementation for vector arithmetic types
public extension Tweenable where Self: VectorArithmetic {

    /// Linearly interpolates between two vector values
    /// - Parameters:
    ///   - lhs: Starting value when t=0
    ///   - rhs: Ending value when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: An interpolated vector
    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        var result = rhs - lhs
        result.scale(by: t)
        return result + lhs
    }
}

/// Tweenable implementation for Dictionary types with Tweenable values
extension Dictionary: Tweenable where Value: Tweenable {

    /// Linearly interpolates between two dictionaries with the same keys
    /// 
    /// - When a key exists in both dictionaries, the values are interpolated
    /// - When a key exists only in one dictionary, it will appear in the result
    ///   only when t < 0.5 (for lhs keys) or t > 0.5 (for rhs keys)
    ///
    /// - Parameters:
    ///   - lhs: Starting dictionary when t=0
    ///   - rhs: Ending dictionary when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: A dictionary with interpolated values
    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        var result = Self()
        
        // Get all keys from both dictionaries
        let allKeys = Set(lhs.keys).union(Set(rhs.keys))
        
        for key in allKeys {
            if let lhsValue = lhs[key], let rhsValue = rhs[key] {
                // Both dictionaries have this key, interpolate between values
                result[key] = Value.lerp(lhsValue, rhsValue, t)
            } else if let lhsValue = lhs[key] {
                // Only left dictionary has this key
                // For t < 0.5, use lhs value; for t >= 0.5, this key doesn't exist in result
                if t < 0.5 {
                    // Scale the value's existence based on t
                    result[key] = Value.lerp(lhsValue, lhsValue, 0)
                }
            } else if let rhsValue = rhs[key] {
                // Only right dictionary has this key
                // For t > 0.5, this key doesn't exist in result; for t < 0.5, use rhs value
                if t > 0.5 {
                    // Scale the value's existence based on t
                    result[key] = Value.lerp(rhsValue, rhsValue, 0)
                }
            }
        }
        return result
    }
}

/// Tweenable implementation for collection types with Tweenable elements
extension RangeReplaceableCollection where Element: Tweenable {

    /// Linearly interpolates between two collections of Tweenable elements
    ///
    /// The interpolation handles collections of different sizes by:
    /// - Interpolating corresponding elements for overlapping indices
    /// - Fading in/out elements that exist only in one collection
    /// - Adjusting collection size based on interpolation factor
    ///
    /// - Parameters:
    ///   - lhs: Starting collection when t=0
    ///   - rhs: Ending collection when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: A collection with interpolated elements
    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        var result = Self()
        
        // Get the count of both collections
        let lhsCount = lhs.count
        let rhsCount = rhs.count
        
        // Determine the target count based on interpolation
        let targetCount = Int(round(Double(lhsCount) + Double(rhsCount - lhsCount) * t))
        
        // Handle the elements that exist in both collections
        let commonCount = Swift.min(lhsCount, rhsCount)
        
        // Interpolate between corresponding elements
        var lhsIterator = lhs.makeIterator()
        var rhsIterator = rhs.makeIterator()
        
        for _ in 0..<commonCount {
            if let lhsElement = lhsIterator.next(), let rhsElement = rhsIterator.next() {
                // Interpolate between the two elements
                result.append(.lerp(lhsElement, rhsElement, t))
            }
        }
        
        // If we need more elements to reach the target count,
        // fade in remaining elements from the longer collection
        if targetCount > commonCount {
            if lhsCount > commonCount {
                // Add remaining elements from lhs with decreasing weight
                let remainingCount = targetCount - commonCount
                let remainingElements = lhs.dropFirst(commonCount).prefix(remainingCount)
                
                for element in remainingElements {
                    // Fade out the element as t increases
                    let fadeWeight = 1.0 - t
                    result.append(.lerp(element, element, fadeWeight))
                }
            } else if rhsCount > commonCount {
                // Add remaining elements from rhs with increasing weight
                let remainingCount = targetCount - commonCount
                let remainingElements = rhs.dropFirst(commonCount).prefix(remainingCount)
                
                for element in remainingElements {
                    // Fade in the element as t increases
                    let fadeWeight = t
                    result.append(.lerp(element, element, fadeWeight))
                }
            }
        }
        
        return result
    }
}

// Standard numeric type Tweenable implementations
/// Double implementation of Tweenable
extension Double: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * t + lhs } }
/// Float implementation of Tweenable
extension Float: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
/// Float16 implementation of Tweenable
extension Float16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
/// CGFloat implementation of Tweenable
extension CGFloat: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
/// Int implementation of Tweenable
extension Int: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// Int8 implementation of Tweenable
extension Int8: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// Int16 implementation of Tweenable
extension Int16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// Int32 implementation of Tweenable
extension Int32: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// Int64 implementation of Tweenable
extension Int64: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// UInt implementation of Tweenable
extension UInt: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// UInt8 implementation of Tweenable
extension UInt8: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// UInt16 implementation of Tweenable
extension UInt16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// UInt32 implementation of Tweenable
extension UInt32: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
/// UInt64 implementation of Tweenable
extension UInt64: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }

// Collection type Tweenable implementations
/// Array implementation of Tweenable for elements that are Tweenable
extension Array: Tweenable where Element: Tweenable {}
/// ContiguousArray implementation of Tweenable for elements that are Tweenable
extension ContiguousArray: Tweenable where Element: Tweenable {}
/// ArraySlice implementation of Tweenable for elements that are Tweenable
extension ArraySlice: Tweenable where Element: Tweenable {}
/// AnimatablePair implementation of Tweenable
extension AnimatablePair: Tweenable {}
/// EmptyAnimatableData implementation of Tweenable
extension EmptyAnimatableData: Tweenable {}

/// EdgeInsets implementation of Tweenable
extension EdgeInsets: Tweenable {

    /// Linearly interpolates between two EdgeInsets values
    /// - Parameters:
    ///   - lhs: Starting EdgeInsets when t=0
    ///   - rhs: Ending EdgeInsets when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated EdgeInsets
    public static func lerp(_ lhs: EdgeInsets, _ rhs: EdgeInsets, _ t: Double) -> EdgeInsets {
        EdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            leading: .lerp(lhs.leading, rhs.leading, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            trailing: .lerp(lhs.trailing, rhs.trailing, t)
        )
    }
}

extension Angle: Tweenable {

    public static func lerp(_ lhs: Angle, _ rhs: Angle, _ t: Double) -> Angle {
        .radians(.lerp(lhs.radians, rhs.radians, t))
    }
}

/// NSDirectionalEdgeInsets implementation of Tweenable
extension NSDirectionalEdgeInsets: Tweenable {

    /// Linearly interpolates between two NSDirectionalEdgeInsets values
    /// - Parameters:
    ///   - lhs: Starting NSDirectionalEdgeInsets when t=0
    ///   - rhs: Ending NSDirectionalEdgeInsets when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated NSDirectionalEdgeInsets
    public static func lerp(_ lhs: NSDirectionalEdgeInsets, _ rhs: NSDirectionalEdgeInsets, _ t: Double) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            leading: .lerp(lhs.leading, rhs.leading, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            trailing: .lerp(lhs.trailing, rhs.trailing, t)
        )
    }
}

/// Date implementation of Tweenable
extension Date: Tweenable {

    /// Linearly interpolates between two Date values
    /// - Parameters:
    ///   - lhs: Starting Date when t=0
    ///   - rhs: Ending Date when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated Date
    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        Date(timeIntervalSince1970: .lerp(lhs.timeIntervalSince1970, rhs.timeIntervalSince1970, t))
    }
}

#if canImport(UIKit)
/// UIColor implementation of Tweenable
extension UIColor: Tweenable {

    /// Linearly interpolates between two UIColor values in RGB color space
    /// - Parameters:
    ///   - lhs: Starting UIColor when t=0
    ///   - rhs: Ending UIColor when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated UIColor
    public static func lerp(_ lhs: UIColor, _ rhs: UIColor, _ t: Double) -> Self {
        // Get components from both colors in same color space (RGB)
        var lhsR: CGFloat = 0, lhsG: CGFloat = 0, lhsB: CGFloat = 0, lhsA: CGFloat = 0
        var rhsR: CGFloat = 0, rhsG: CGFloat = 0, rhsB: CGFloat = 0, rhsA: CGFloat = 0
        
        lhs.getRed(&lhsR, green: &lhsG, blue: &lhsB, alpha: &lhsA)
        rhs.getRed(&rhsR, green: &rhsG, blue: &rhsB, alpha: &rhsA)
        
        // Linearly interpolate each component
        let t = CGFloat(max(0, min(1, t))) // Clamp t between 0 and 1
        let r = lhsR + (rhsR - lhsR) * t
        let g = lhsG + (rhsG - lhsG) * t
        let b = lhsB + (rhsB - lhsB) * t
        let a = lhsA + (rhsA - lhsA) * t
        
        return Self(red: r, green: g, blue: b, alpha: a)
    }
}

/// SwiftUI Color implementation of Tweenable (iOS)
extension Color: Tweenable {

    /// Linearly interpolates between two Color values
    /// - Parameters:
    ///   - lhs: Starting Color when t=0
    ///   - rhs: Ending Color when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated Color
    public static func lerp(_ lhs: Color, _ rhs: Color, _ t: Double) -> Color {
        // Convert SwiftUI Color to UIColor, interpolate, then convert back
        let lhsUIColor = UIColor(lhs)
        let rhsUIColor = UIColor(rhs)
        
        // Use the UIColor lerp implementation
        let interpolatedUIColor = UIColor.lerp(lhsUIColor, rhsUIColor, t)
        
        // Convert back to SwiftUI Color
        return Color(interpolatedUIColor)
    }
}

/// UIEdgeInsets implementation of Tweenable
extension UIEdgeInsets: Tweenable {

    /// Linearly interpolates between two UIEdgeInsets values
    /// - Parameters:
    ///   - lhs: Starting UIEdgeInsets when t=0
    ///   - rhs: Ending UIEdgeInsets when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated UIEdgeInsets
    public static func lerp(_ lhs: UIEdgeInsets, _ rhs: UIEdgeInsets, _ t: Double) -> UIEdgeInsets {
        UIEdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            left: .lerp(lhs.left, rhs.left, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            right: .lerp(lhs.right, rhs.right, t)
        )
    }
}

#endif

// MARK: - CoreGraphics Types

extension CGPoint: Tweenable {
    public static func lerp(_ lhs: CGPoint, _ rhs: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(
            x: CGFloat.lerp(lhs.x, rhs.x, t),
            y: CGFloat.lerp(lhs.y, rhs.y, t)
        )
    }
}

extension CGSize: Tweenable {
    public static func lerp(_ lhs: CGSize, _ rhs: CGSize, _ t: Double) -> CGSize {
        CGSize(
            width: CGFloat.lerp(lhs.width, rhs.width, t),
            height: CGFloat.lerp(lhs.height, rhs.height, t)
        )
    }
}

extension CGRect: Tweenable {
    public static func lerp(_ lhs: CGRect, _ rhs: CGRect, _ t: Double) -> CGRect {
        CGRect(
            origin: .lerp(lhs.origin, rhs.origin, t),
            size: .lerp(lhs.size, rhs.size, t)
        )
    }
}

extension CGAffineTransform: Tweenable {
    public static func lerp(_ lhs: CGAffineTransform, _ rhs: CGAffineTransform, _ t: Double) -> CGAffineTransform {
        CGAffineTransform(
            a: CGFloat.lerp(lhs.a, rhs.a, t),
            b: CGFloat.lerp(lhs.b, rhs.b, t),
            c: CGFloat.lerp(lhs.c, rhs.c, t),
            d: CGFloat.lerp(lhs.d, rhs.d, t),
            tx: CGFloat.lerp(lhs.tx, rhs.tx, t),
            ty: CGFloat.lerp(lhs.ty, rhs.ty, t)
        )
    }
}

extension CATransform3D: Tweenable {
    public static func lerp(_ lhs: CATransform3D, _ rhs: CATransform3D, _ t: Double) -> CATransform3D {
        CATransform3D(
            m11: CGFloat.lerp(lhs.m11, rhs.m11, t),
            m12: CGFloat.lerp(lhs.m12, rhs.m12, t),
            m13: CGFloat.lerp(lhs.m13, rhs.m13, t),
            m14: CGFloat.lerp(lhs.m14, rhs.m14, t),
            m21: CGFloat.lerp(lhs.m21, rhs.m21, t),
            m22: CGFloat.lerp(lhs.m22, rhs.m22, t),
            m23: CGFloat.lerp(lhs.m23, rhs.m23, t),
            m24: CGFloat.lerp(lhs.m24, rhs.m24, t),
            m31: CGFloat.lerp(lhs.m31, rhs.m31, t),
            m32: CGFloat.lerp(lhs.m32, rhs.m32, t),
            m33: CGFloat.lerp(lhs.m33, rhs.m33, t),
            m34: CGFloat.lerp(lhs.m34, rhs.m34, t),
            m41: CGFloat.lerp(lhs.m41, rhs.m41, t),
            m42: CGFloat.lerp(lhs.m42, rhs.m42, t),
            m43: CGFloat.lerp(lhs.m43, rhs.m43, t),
            m44: CGFloat.lerp(lhs.m44, rhs.m44, t)
        )
    }
}

#if canImport(AppKit)
/// NSColor implementation of Tweenable
extension NSColor: Tweenable {
    
    /// Linearly interpolates between two NSColor values in sRGB color space
    /// - Parameters:
    ///   - lhs: Starting NSColor when t=0
    ///   - rhs: Ending NSColor when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated NSColor
    public static func lerp(_ lhs: NSColor, _ rhs: NSColor, _ t: Double) -> Self {
        // Convert both colors to the calibrated RGB color space
        guard let lhsRGB = lhs.usingColorSpace(.sRGB),
              let rhsRGB = rhs.usingColorSpace(.sRGB) else {
            return lhs as! Self // Fallback if conversion fails
        }
        
        // Extract components from both colors
        var lhsR: CGFloat = 0, lhsG: CGFloat = 0, lhsB: CGFloat = 0, lhsA: CGFloat = 0
        var rhsR: CGFloat = 0, rhsG: CGFloat = 0, rhsB: CGFloat = 0, rhsA: CGFloat = 0
        
        lhsRGB.getRed(&lhsR, green: &lhsG, blue: &lhsB, alpha: &lhsA)
        rhsRGB.getRed(&rhsR, green: &rhsG, blue: &rhsB, alpha: &rhsA)
        
        // Linearly interpolate each component
        let t = CGFloat(max(0, min(1, t))) // Clamp t between 0 and 1
        let r = lhsR + (rhsR - lhsR) * t
        let g = lhsG + (rhsG - lhsG) * t
        let b = lhsB + (rhsB - lhsB) * t
        let a = lhsA + (rhsA - lhsA) * t
        
        // Create and return the interpolated color
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a) as! Self
    }
}

/// SwiftUI Color implementation of Tweenable (macOS)
extension Color: Tweenable {

    /// Linearly interpolates between two Color values
    /// - Parameters:
    ///   - lhs: Starting Color when t=0
    ///   - rhs: Ending Color when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated Color
    public static func lerp(_ lhs: Color, _ rhs: Color, _ t: Double) -> Color {
        // Convert SwiftUI Color to NSColor
        let lhsNSColor = NSColor(lhs)
        let rhsNSColor = NSColor(rhs)
        
        // Use the NSColor lerp implementation
        let interpolatedNSColor = NSColor.lerp(lhsNSColor, rhsNSColor, t)
        
        // Convert back to SwiftUI Color
        return Color(interpolatedNSColor)
    }
}

/// NSEdgeInsets implementation of Tweenable
extension NSEdgeInsets: Tweenable {

    /// Linearly interpolates between two NSEdgeInsets values
    /// - Parameters:
    ///   - lhs: Starting NSEdgeInsets when t=0
    ///   - rhs: Ending NSEdgeInsets when t=1
    ///   - t: Interpolation factor (typically between 0 and 1)
    /// - Returns: Interpolated NSEdgeInsets
    public static func lerp(_ lhs: NSEdgeInsets, _ rhs: NSEdgeInsets, _ t: Double) -> NSEdgeInsets {
        NSEdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            left: .lerp(lhs.left, rhs.left, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            right: .lerp(lhs.right, rhs.right, t)
        )
    }
}

#endif
