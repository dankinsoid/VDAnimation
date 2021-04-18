//
//  Color++.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import UIKit
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Color: Animatable {
	
	public var animatableData: UIColor.AnimatableData {
		get {
			if #available(iOS 14.0, *) {
				return UIColor(self).rgba
			} else {
				return components()
			}
		}
		set {
			self = Color(.sRGB, red: Double(newValue.red), green: Double(newValue.green), blue: Double(newValue.blue), opacity: Double(newValue.alpha))
		}
	}
	
	private func components() -> UIColor.AnimatableData {
		let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
		var hexNumber: UInt64 = 0
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
		
		let result = scanner.scanHexInt64(&hexNumber)
		if result {
			r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
			g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
			b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
			a = CGFloat(hexNumber & 0x000000ff) / 255
		}
		return UIColor.AnimatableData(red: r, green: g, blue: b, alpha: a)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIColor {
	
	public struct AnimatableData: VectorArithmetic {
		
		public static var zero: AnimatableData { AnimatableData(red: 0, green: 0, blue: 0, alpha: 0) }
		
		public var red: CGFloat
		public var green: CGFloat
		public var blue: CGFloat
		public var alpha: CGFloat
		
		public mutating func scale(by rhs: Double) {
			let rhs = CGFloat(rhs)
			self = AnimatableData(red: red * rhs, green: green * rhs, blue: blue * rhs, alpha: alpha * rhs)
		}
		
		public var magnitudeSquared: Double {
			AnimatablePair(AnimatablePair(red, blue), AnimatablePair(green, alpha)).magnitudeSquared
		}
		
		public static func +(lhs: AnimatableData, rhs: AnimatableData) -> AnimatableData {
			AnimatableData(red: lhs.red + rhs.red, green: lhs.green + rhs.green, blue: lhs.blue + rhs.blue, alpha: lhs.alpha + rhs.alpha)
		}
		
		public static func +=(lhs: inout AnimatableData, rhs: AnimatableData) {
			lhs = lhs + rhs
		}
		
		public static func -(lhs: AnimatableData, rhs: AnimatableData) -> AnimatableData {
			AnimatableData(red: lhs.red - rhs.red, green: lhs.green - rhs.green, blue: lhs.blue - rhs.blue, alpha: lhs.alpha - rhs.alpha)
		}
		
		public static func -=(lhs: inout AnimatableData, rhs: AnimatableData) {
			lhs = lhs - rhs
		}
		
	}
	
	public var rgba: AnimatableData {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		if getRed(&r, green: &g, blue: &b, alpha: &a) {
			return AnimatableData(red: r, green: g, blue: b, alpha: a)
		}
		return .zero
	}
}
