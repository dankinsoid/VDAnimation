//
//  TransitionType.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import Foundation

public enum TransitionType {
	case present, dismiss, pop, push, set
	public var show: Bool {
		self == .present || self == .push || self == .set
	}
	var inverted: TransitionType {
		switch self {
		case .dismiss: return .present
		case .present: return .dismiss
		case .pop: return .push
		case .push: return .pop
		case .set: return .dismiss
		}
	}
}
