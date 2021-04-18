//
//  TransitionType.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import Foundation

public enum TransitionType {
	case present, dismiss, pop, push, next, previous
	public var show: Bool {
		self == .present || self == .push || self == .next
	}
	public var isNavigation: Bool {
		self == .pop || self == .push
	}
	public var isTabs: Bool {
		self == .next || self == .previous
	}
	var inverted: TransitionType {
		switch self {
		case .dismiss: return .present
		case .present: return .dismiss
		case .pop: return .push
		case .push: return .pop
		case .next: return .previous
		case .previous: return .next
		}
	}
}
