//
//  File.swift
//  
//
//  Created by Данил Войдилов on 08.02.2021.
//

import XCTest
@testable import VDAnimation

final class VDTests: XCTestCase {
	
	let animation = Interval()
	
	var animations: [VDAnimationProtocol] {
		[
			animation, animation.repeat(5), animation.reversed(), animation.autoreverse(), Instant {},
			Sequential([animation, animation, animation]), Parallel([animation, animation, animation]),
			TimerAnimation { _ in }
		]
	}
	
	func testIsRunning() {
		animations.forEach(isRunningTest)
	}
	
	func testProgress() {
		animations.forEach(progressTest)
	}
	
	func testDuration() {
		animations.forEach(durationTest)
	}
	
	func testComplete() {
		animations.forEach(completeTest)
	}
	
	func testIsReversed() {
		animations.forEach(isReversedTest)
	}
	
	func testDelegateOptions() {
		animations.forEach(delegateOptionsTest)
	}
	
	static var allTests = [
		("testIsRunning", testIsRunning),
		("testProgress", testProgress),
		("testDuration", testDuration),
		("testComplete", testComplete),
		("testIsReversed", testIsReversed),
		("testDelegateOptions", testDelegateOptions)
	]
	
	func isRunningTest(animation: VDAnimationProtocol) {
		let delegate = animation.duration(0.25).delegate()
		XCTAssert(delegate.isRunning, false, "isRunning", animation)
		delegate.play()
		if delegate.isInstant {
			XCTAssert(delegate.isRunning, false, "isRunning", animation)
			return
		}
		XCTAssert(delegate.isRunning, true, "isRunning", animation)
		delegate.pause()
		XCTAssert(delegate.isRunning, false, "isRunning", animation)
		delegate.stop()
		XCTAssert(delegate.isRunning, false, "isRunning", animation)
	}
	
	func progressTest(animation: VDAnimationProtocol) {
		let delegate = animation.duration(0.25).delegate()
		delegate.play()
		delegate.pause()
		for _ in 0..<10 {
			let position = Double.random(in: 0...1)
			delegate.progress = position
			XCTAssert(delegate.progress, position, "progress", animation)
		}
		delegate.stop()
	}
	
	func durationTest(animation: VDAnimationProtocol) {
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
			approximately(realDuration, expectedDuration) || abs(realDuration - expectedDuration) < 0.05,
			"\(type(of: animation)) Expected duration: \(expectedDuration), real: \(realDuration)"
		)
	}
	
	func completeTest(animation: VDAnimationProtocol) {
		
		func test(_ animation: VDAnimationProtocol, complete: Bool) {
			let delegate = animation.duration(0.1).delegate(with: .complete(complete))
			guard !delegate.isInstant else { return }
			var exp: XCTestExpectation? = expectation(description: "completion \(#line) \(type(of: animation))")
			delegate.add(completion: {_ in exp?.fulfill() })
			delegate.play()
			waitForExpectations(timeout: 0.12)
			exp = nil
			delegate.play(with: .isReversed(delegate.options.isReversed != true))
			XCTAssert(delegate.isRunning, !complete, "isRunning", animation)
			delegate.stop()
		}
		
		test(animation, complete: true)
		test(animation, complete: false)
	}
	
	func isReversedTest(animation: VDAnimationProtocol) {
		
		func test(_ animation: VDAnimationProtocol, reversed: Bool) {
			let delegate = animation.duration(0.2).delegate(with: .isReversed(reversed))
			guard !delegate.isInstant else { return }
			let exp = expectation(description: "completion \(#line) \(type(of: animation))")
			delegate.progress = 0.5
			delegate.play()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
				delegate.pause()
				exp.fulfill()
			}
			waitForExpectations(timeout: 0.1)
			XCTAssert(
				(delegate.progress < 0.5) == reversed,
				"isReversed \(reversed), \(delegate.options.isReversed ?? false) \(delegate.progress) \(type(of: animation))"
			)
			delegate.stop()
		}
		
		test(animation, reversed: true)
		test(animation, reversed: false)
	}
	
	func delegateOptionsTest(animation: VDAnimationProtocol) {
		let options1 = AnimationOptions(duration: .absolute(0.5), curve: .easeInOut, complete: true, isReversed: true)
		let delegate1 = animation.delegate(with: options1)
		XCTAssert(delegate1.options.duration, delegate1.isInstant ? .absolute(0) : .absolute(0.5), "absolute duration", animation)
		XCTAssert(delegate1.options.curve, delegate1.isInstant ? nil : .easeInOut, "curve", animation)
		XCTAssert(delegate1.options.complete, true, "complete", animation)
		XCTAssert(delegate1.options.isReversed, delegate1.isInstant ? nil : true, "isReversed", animation)
		
		let options2 = AnimationOptions(duration: .relative(0.5), curve: .ease, complete: false, isReversed: false)
		let delegate2 = animation.delegate(with: options2)
		XCTAssert(delegate2.options.duration, delegate2.isInstant ? .absolute(0) : .relative(0.5), "relative duration", animation)
		XCTAssert(delegate2.options.curve, delegate2.isInstant ? nil : .ease, "curve", animation)
		XCTAssert(delegate2.options.complete, delegate2.isInstant, "complete", animation)
		XCTAssert(delegate2.options.isReversed, delegate2.isInstant ? nil : false, "isReversed", animation)
	}
	
	func continueTest(animation: VDAnimationProtocol) {}
}

func XCTAssert<B: Equatable>(_ value: B, _ expected: B, _ name: String, _ animation: VDAnimationProtocol, file: StaticString = #file, line: UInt = #line) {
	XCTAssert(value == expected, "\(line) \(type(of: animation))\n Expected \(name) \(expected) but got \(value)")
}

func XCTAssert(_ value: Double, _ expected: Double, _ name: String, _ animation: VDAnimationProtocol, file: StaticString = #file, line: UInt = #line) {
	XCTAssert(approximately(value, expected), "\(line) \(type(of: animation))\n Expected \(name) \(expected) but got \(value)")
}

private func approximately(_ lhs: Double, _ rhs: Double, accuracy: Double = 1.01) -> Bool {
	abs(max(lhs, rhs)) / max(0.0000001, abs(min(lhs, rhs))) < accuracy
}
