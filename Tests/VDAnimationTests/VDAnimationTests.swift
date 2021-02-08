//
//  File.swift
//  
//
//  Created by Данил Войдилов on 08.02.2021.
//

import XCTest
@testable import VDAnimation

final class VDTests: XCTestCase {
	
	func tests() {
		let view = UIView()
		let expectation = XCTestExpectation()
		Instant {
			print("hmm")
			view.backgroundColor = .black
		}
		.duration(2)
		.repeat(5)
		.start {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 150)
	}
	
	static var allTests = [
		("tests", tests),
	]
	
}
