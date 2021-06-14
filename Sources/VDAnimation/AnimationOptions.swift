//
//  AnimationOptions.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

public struct AnimationOptions: Equatable, ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = AnimationOptions
	
	public static var empty: AnimationOptions { AnimationOptions() }
	public static func duration(_ duration: AnimationDuration?) -> AnimationOptions { .init(duration: duration) }
	public static func curve(_ curve: BezierCurve?) -> AnimationOptions { .init(curve: curve) }
	public static func complete(_ complete: Bool?) -> AnimationOptions { .init(complete: complete) }
	public static func isReversed(_ isReversed: Bool?) -> AnimationOptions { .init(isReversed: isReversed) }
	
	public var duration: AnimationDuration?
	public var curve: BezierCurve?
	public var complete: Bool?
	public var isReversed: Bool?
	
	public init(arrayLiteral elements: AnimationOptions...) {
		if elements.isEmpty {
			self = .init()
		} else {
			self = elements.dropFirst().reduce(elements[0]) { $0.or($1) }
		}
	}
	
	public init(
		duration: AnimationDuration? = nil,
		curve: BezierCurve? = nil,
	  complete: Bool? = nil,
	 	isReversed: Bool? = nil
	) {
		self.duration = duration
		self.curve = curve
		self.complete = complete
		self.isReversed = isReversed
	}
	
	public init() {}
	
	public func or(_ other: AnimationOptions) -> AnimationOptions {
		AnimationOptions(
			duration: duration ?? other.duration,
			curve: curve ?? other.curve,
			complete: complete ?? other.complete,
			isReversed: isReversed ?? other.isReversed
		)
	}
	
	public func set(_ other: AnimationOptions) -> AnimationOptions {
		other.or(self)
	}
}

public enum AnimationPosition: ExpressibleByFloatLiteral, Equatable {
	case start, progress(Double), end
	
	public var complete: Double {
		switch self {
		case .start:            return 0
		case .progress(let k):  return k
		case .end:              return 1
		}
	}
	
	public var reversed: AnimationPosition {
		switch self {
		case .start:            return .end
		case .progress(let k):  return .progress(1 - k)
		case .end:              return .start
		}
	}
	
	public init(floatLiteral value: Double) {
		switch value {
		case 0: self = .start
		case 1: self = .end
		default: self = .progress(value)
		}
	}
	
	public static func ==(_ lhs: AnimationPosition, _ rhs: AnimationPosition) -> Bool {
		lhs.complete == rhs.complete
	}
}

extension Optional where Wrapped == AnimationPosition {
	public static var current: AnimationPosition? { nil }
}

public enum AutoreverseStep: Equatable {
	case forward, back
	
	public var inverted: AutoreverseStep {
		switch self {
		case .forward:  return .back
		case .back:     return .forward
		}
	}
}
