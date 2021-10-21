//
//  AnimationModifier.swift
//  VDTransition
//
//  Created by Данил Войдилов on 15.04.2021.
//

import SwiftUI
import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct AnimationModifier: AnimatableModifier {
	let valueSubject: ValueObservable<AnimatableData>
	
	var animatableData: AnimatableData {
		didSet {
			valueSubject.value = animatableData
		}
	}
	
	init(valueSubject: ValueObservable<AnimatableData>, current: AnimatableData) {
		animatableData = current
		self.valueSubject = valueSubject
	}
	
	func body(content: Content) -> some View {
		content
	}
	
	struct AnimatableData: VectorArithmetic {
		static var zero: AnimationModifier.AnimatableData { .init() }
		var values: [UUID: Double]
		var magnitudeSquared: Double {
			(values.reduce(0, { $0 + $1.value }) / Double(max(1, values.count))).magnitudeSquared
		}
		
		init(_ values: [UUID: Double] = [:]) {
			self.values = values
		}
		
		mutating func scale(by rhs: Double) {
			values = values.mapValues { $0 * rhs }
		}
		
		static func +(lhs: AnimationModifier.AnimatableData, rhs: AnimationModifier.AnimatableData) -> AnimationModifier.AnimatableData {
			.init(lhs.values.merging(rhs.values, uniquingKeysWith: +))
		}
		
		static func -(lhs: AnimationModifier.AnimatableData, rhs: AnimationModifier.AnimatableData) -> AnimationModifier.AnimatableData {
			.init(lhs.values.merging(rhs.values, uniquingKeysWith: -))
		}
	}
}
