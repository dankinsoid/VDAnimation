//
//  Clojures.swift
//  VDTransition
//
//  Created by Данил Войдилов on 23.04.2021.
//

import Foundation

public func +=(_ lhs: inout (() -> Void)?, _ rhs: (() -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l()
		r()
	}
}

public func +=<In>(_ lhs: inout ((In) -> Void)?, _ rhs: ((In) -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l($0)
		r($0)
	}
}

public func +=<_0, _1>(_ lhs: inout ((_0, _1) -> Void)?, _ rhs: ((_0, _1) -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l($0, $1)
		r($0, $1)
	}
}

public func +=<_0, _1, _2>(_ lhs: inout ((_0, _1, _2) -> Void)?, _ rhs: ((_0, _1, _2) -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l($0, $1, $2)
		r($0, $1, $2)
	}
}

public func +=<_0, _1, _2, _3>(_ lhs: inout ((_0, _1, _2, _3) -> Void)?, _ rhs: ((_0, _1, _2, _3) -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l($0, $1, $2, $3)
		r($0, $1, $2, $3)
	}
}

public func +=<_0, _1, _2, _3, _4>(_ lhs: inout ((_0, _1, _2, _3, _4) -> Void)?, _ rhs: ((_0, _1, _2, _3, _4) -> Void)?) {
	guard let l = lhs, let r = rhs else { return }
	lhs = {
		l($0, $1, $2, $3, $4)
		r($0, $1, $2, $3, $4)
	}
}
