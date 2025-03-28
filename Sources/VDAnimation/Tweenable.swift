import SwiftUI

public protocol Tweenable {

    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self
}

public extension Tweenable where Self: BinaryFloatingPoint {

    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs }
}

extension Tweenable where Self: BinaryInteger {

    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs }
}

public extension Tweenable where Self: VectorArithmetic {

    static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        var result = rhs - lhs
        result.scale(by: t)
        return result + lhs
    }
}

extension Dictionary: Tweenable where Value: Tweenable {

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

extension RangeReplaceableCollection where Element: Tweenable {

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

extension Double: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * t + lhs } }
extension Float: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
extension Float16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
extension CGFloat: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { (rhs - lhs) * Self(t) + lhs } }
extension Int: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension Int8: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension Int16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension Int32: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension Int64: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension UInt: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension UInt8: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension UInt16: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension UInt32: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension UInt64: Tweenable { public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self { Self(Double(rhs - lhs) * t) + lhs } }
extension Array: Tweenable where Element: Tweenable {}
extension ContiguousArray: Tweenable where Element: Tweenable {}
extension ArraySlice: Tweenable where Element: Tweenable {}
extension AnimatablePair: Tweenable {}
extension EmptyAnimatableData: Tweenable {}

extension EdgeInsets: Tweenable {

    public static func lerp(_ lhs: EdgeInsets, _ rhs: EdgeInsets, _ t: Double) -> EdgeInsets {
        EdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            leading: .lerp(lhs.leading, rhs.leading, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            trailing: .lerp(lhs.trailing, rhs.trailing, t)
        )
    }
}

extension NSDirectionalEdgeInsets: Tweenable {

    public static func lerp(_ lhs: NSDirectionalEdgeInsets, _ rhs: NSDirectionalEdgeInsets, _ t: Double) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(
            top: .lerp(lhs.top, rhs.top, t),
            leading: .lerp(lhs.leading, rhs.leading, t),
            bottom: .lerp(lhs.bottom, rhs.bottom, t),
            trailing: .lerp(lhs.trailing, rhs.trailing, t)
        )
    }
}

extension Date: Tweenable {

    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        Date(timeIntervalSince1970: .lerp(lhs.timeIntervalSince1970, rhs.timeIntervalSince1970, t))
    }
}

#if canImport(UIKit)
extension UIColor: Tweenable {

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

extension Color: Tweenable {

    public static func lerp(_ lhs: Color, _ rhs: Color, _ t: Double) -> Color {
        // Convert SwiftUI Color to UIColor, interpolate, then convert back
        // This approach works for iOS 14+
        let lhsUIColor = UIColor(lhs)
        let rhsUIColor = UIColor(rhs)
        
        // Use the UIColor lerp implementation
        let interpolatedUIColor = UIColor.lerp(lhsUIColor, rhsUIColor, t)
        
        // Convert back to SwiftUI Color
        return Color(interpolatedUIColor)
    }
}

extension UIEdgeInsets: Tweenable {

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

#if canImport(AppKit)
extension NSColor: Tweenable {
    
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

extension Color: Tweenable {

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

extension NSEdgeInsets: Tweenable {

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
