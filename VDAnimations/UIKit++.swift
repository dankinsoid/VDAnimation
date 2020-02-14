//
//  UIKit++.swift
//  CA
//
//  Created by crypto_user on 11.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

extension UIView {
    
    public var x: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }
    public var y: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }
    public var width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }
    public var height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }
    
}

extension CGAffineTransform {
    
    public static func scale<F: BinaryFloatingPoint>(_ x: F, _ y: F) -> CGAffineTransform {
        CGAffineTransform(scaleX: CGFloat(x), y: CGFloat(y))
    }
    
    public static func scale<F: BinaryFloatingPoint>(_ k: F) -> CGAffineTransform {
        let f = CGFloat(k)
        return CGAffineTransform(scaleX: f, y: f)
    }
    
    public static func rotate<F: BinaryFloatingPoint>(_ angle: F) -> CGAffineTransform {
        CGAffineTransform(rotationAngle: CGFloat(angle))
    }
    
    public static func translate<F: BinaryFloatingPoint>(_ x: F, _ y: F) -> CGAffineTransform {
        CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
    }
    
}

extension CATransform3D {
    
    public static func rotate<F: BinaryFloatingPoint>(_ angle: F, x: F = 0, y: F = 1, z: F = 0) -> CATransform3D {
        CATransform3DRotate(CATransform3DIdentity, CGFloat(angle), CGFloat(x), CGFloat(y), CGFloat(z))
    }
    
}
