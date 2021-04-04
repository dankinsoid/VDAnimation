//
//  Operators.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation
import VDKit

extension VDAnimationProtocol {
	
	public func duration(_ value: TimeInterval) -> VDAnimationProtocol {
		modified.chain.options.duration[.absolute(value)].apply()
	}
	
	public func duration<F: BinaryFloatingPoint>(relative value: F) -> VDAnimationProtocol {
		modified.chain.options.duration[.relative(Double(value))].apply()
	}
	
	public func curve(_ value: BezierCurve) -> VDAnimationProtocol {
		modified.chain.options.curve[value].apply()
	}
	
	public func curve<F: BinaryFloatingPoint>(_ p1: (x: F, y: F), _ p2: (x: F, y: F)) -> VDAnimationProtocol {
		modified.chain.options.curve[.init(p1, p2)].apply()
	}
	
	public func `repeat`(_ count: Int) -> VDAnimationProtocol {
		RepeatAnimation(count, for: self)
	}
	
	public func `repeat`() -> VDAnimationProtocol {
		RepeatAnimation(nil, for: self)
	}
	
	public func autoreverse() -> VDAnimationProtocol {
		Autoreverse(self)
	}
	
	public func reversed() -> VDAnimationProtocol {
		ReversedAnimation(animation: self)
	}
	
	public func autoreverse(repeat count: Int) -> VDAnimationProtocol {
		RepeatAnimation(count, for: Autoreverse(self))
	}
	
	public func delay<F: BinaryFloatingPoint>(_ value: F) -> VDAnimationProtocol {
		guard value > .zero else { return self }
		return Sequential {
			Interval(value)
			self
		}
	}
	
	public func delay<F: BinaryFloatingPoint>(relative value: F) -> VDAnimationProtocol {
		Sequential {
			Interval(relative: value)
			self
		}
	}
}

private func curve(_ lhs: BezierCurve?, _ rhs: BezierCurve?) -> BezierCurve? {
	guard let l = lhs, let r = rhs else {
		return lhs ?? rhs
	}
	return BezierCurve.between(l, r)
}
