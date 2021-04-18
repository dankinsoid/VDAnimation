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
	public var scaleData: UIColor.ScaledData {
		if #available(iOS 14.0, *) {
			return UIColor(self).scaleData
		} else {
			return components()
		}
	}
	
	public var animatableData: UIColor.ScaledData {
		get { scaleData }
		set { self = .init(scaleData: newValue) }
	}
	
	public init(scaleData: UIColor.ScaledData) {
		self = Color(UIColor(scaleData: scaleData))
	}
	
	private func components() -> UIColor.ScaledData {
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
		return UIColor.ScaledData(red: r, green: g, blue: b, alpha: a)
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIColor.ScaledData: VectorArithmetic {
	
	public mutating func scale(by rhs: Double) {
		self = scaled(by: rhs)
	}
	
	public var magnitudeSquared: Double {
		AnimatablePair(AnimatablePair(red, blue), AnimatablePair(green, alpha)).magnitudeSquared
	}
}
