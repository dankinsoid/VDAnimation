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
		let animation: VDAnimationProtocol = Interval()
		[animation, animation.repeat(5)].forEach {//, animation.reversed(), animation.autoreverse(), Instant {}].forEach {
			testIsRunning(animation: $0)
			testProgress(animation: $0)
			testDuration(animation: $0)
			testComplete(animation: $0)
			testIsReversed(animation: $0)
			testDelegateOptions(animation: $0)
			testContinue(animation: $0)
		}
	}
	
	static var allTests = [
		("tests", tests),
	]
	
	func testIsRunning(animation: VDAnimationProtocol) {
		let delegate = animation.duration(0.25).delegate()
		XCTAssert(delegate.isRunning, false, "isRunning")
		delegate.play()
		if delegate.isInstant {
			XCTAssert(delegate.isRunning, false, "isRunning")
			waitForExpectations(timeout: 0)
			return
		}
		XCTAssert(delegate.isRunning, true, "isRunning")
		delegate.pause()
		XCTAssert(delegate.isRunning, false, "isRunning")
		delegate.stop()
		XCTAssert(delegate.isRunning, false, "isRunning")
	}
	
	func testProgress(animation: VDAnimationProtocol) {
		let delegate = animation.duration(0.25).delegate()
		delegate.play()
		delegate.pause()
		for _ in 0..<10 {
			let position = Double.random(in: 0...1)
			delegate.progress = position
			XCTAssert(delegate.progress, position, "progress")
		}
		delegate.stop()
	}
	
	func testDuration(animation: VDAnimationProtocol) {
		let delegate = animation.duration(0.1).delegate()
		let expectedDuration = delegate.options.duration?.absolute ?? 0
		let exp = expectation(description: "completion \(#line)")
		delegate.add { _ in
			exp.fulfill()
		}
		let date = Date()
		delegate.play()
		waitForExpectations(timeout: 2)
		let realDuration = Date().timeIntervalSince(date)
		XCTAssert(
			abs(realDuration - expectedDuration) < expectedDuration / 20 || abs(realDuration - expectedDuration) < 0.05,
			"Expected duration: \(expectedDuration), real: \(realDuration)"
		)
	}
	
	func testComplete(animation: VDAnimationProtocol) {
		
		func test(_ animation: VDAnimationProtocol, complete: Bool) {
			let delegate = animation.duration(0.1).delegate(with: .complete(complete))
			guard !delegate.isInstant else { return }
			var exp: XCTestExpectation? = expectation(description: "completion \(#line)")
			delegate.add(completion: {_ in exp?.fulfill() })
			delegate.play()
			waitForExpectations(timeout: 0.12)
			exp = nil
			delegate.play(with: .isReversed(delegate.options.isReversed != true))
			XCTAssert(delegate.isRunning, !complete, "isRunning")
			delegate.stop()
		}
		
		test(animation, complete: true)
		test(animation, complete: false)
	}
	
	func testIsReversed(animation: VDAnimationProtocol) {
		
		func test(_ animation: VDAnimationProtocol, reversed: Bool) {
			let delegate = animation.duration(0.1).delegate(with: .isReversed(reversed))
			guard !delegate.isInstant else { return }
			let exp = expectation(description: "completion \(#line)")
			delegate.progress = 0.5
			delegate.play()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
				exp.fulfill()
			}
			waitForExpectations(timeout: 0.12)
			delegate.pause()
			XCTAssert((delegate.progress < 0.5) == reversed, "isReversed \(reversed), \(delegate.progress)")
			delegate.stop()
		}
		
		test(animation, reversed: true)
		test(animation, reversed: false)
	}
	
	func testDelegateOptions(animation: VDAnimationProtocol) {
		let options1 = AnimationOptions(duration: .absolute(0.5), curve: .easeInOut, complete: true, isReversed: true)
		let delegate1 = animation.delegate(with: options1)
		XCTAssert(delegate1.options.duration, delegate1.isInstant ? .absolute(0) : .absolute(0.5), "absolute duration")
		XCTAssert(delegate1.options.curve, delegate1.isInstant ? nil : .easeInOut, "curve")
		XCTAssert(delegate1.options.complete, delegate1.isInstant ? nil : true, "complete")
		XCTAssert(delegate1.options.isReversed, delegate1.isInstant ? nil : true, "isReversed")
		
		let options2 = AnimationOptions(duration: .relative(0.5), curve: .ease, complete: false, isReversed: false)
		let delegate2 = animation.delegate(with: options2)
		XCTAssert(delegate2.options.duration, delegate2.isInstant ? .absolute(0) : .relative(0.5), "relative duration")
		XCTAssert(delegate2.options.curve, delegate2.isInstant ? nil : .ease, "curve")
		XCTAssert(delegate2.options.complete, delegate2.isInstant ? nil : false, "complete")
		XCTAssert(delegate2.options.isReversed, delegate2.isInstant ? nil : false, "isReversed")
	}
	
	func testContinue(animation: VDAnimationProtocol) {}
}

public func XCTAssert<B: Equatable>(_ value: B, _ expected: B, _ name: String, file: StaticString = #file, line: UInt = #line) {
	XCTAssert(value == expected, "\(line)\n Expected \(name) \(expected) but got \(value)")
}

public func XCTAssert(_ value: Double, _ expected: Double, _ name: String, file: StaticString = #file, line: UInt = #line) {
	XCTAssert(approximately(value, expected), "\(line)\n Expected \(name) \(expected) but got \(value)")
}

private func approximately(_ lhs: Double, _ rhs: Double, accuracy: Double = 1.01) -> Bool {
	abs(max(lhs, rhs)) / max(0.0000001, abs(min(lhs, rhs))) < accuracy
}
