import XCTest
@testable import VDAnimation

final class MotionTests: XCTestCase {
    
    // MARK: - Basic Motion Tests
    
    func testToMotion() {
        // Test basic transition
        let motion = To<Double>(100.0)
        let data = motion.anyMotion.prepare(0.0, .absolute(1.0))
        
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
        
        // Test with multiple values
        let multiMotion = To<Double>(50.0, 100.0)
        let multiData = multiMotion.anyMotion.prepare(0.0, .absolute(1.0))
        
        XCTAssertEqual(multiData.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(multiData.lerp(0.0, 0.25), 25.0)
        XCTAssertEqual(multiData.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(multiData.lerp(0.0, 0.75), 75.0)
        XCTAssertEqual(multiData.lerp(0.0, 1.0), 100.0)
        
        // Test with different starting value
        XCTAssertEqual(multiData.lerp(20.0, 0.0), 20.0)
        XCTAssertEqual(multiData.lerp(20.0, 0.5), 50.0)
    }
    
    func testWaitMotion() {
        // Test wait with explicit duration
        let motion = Wait<Double>(.absolute(2.0))
        let data = motion.anyMotion.prepare(42.0, .absolute(1.0))
        
        XCTAssertEqual(data.duration?.seconds, 2.0)
        XCTAssertEqual(data.lerp(42.0, 0.0), 42.0)
        XCTAssertEqual(data.lerp(42.0, 1.0), 42.0)
        
        // Test wait with default duration
        let defaultMotion = Wait<Double>()
        let defaultData = defaultMotion.anyMotion.prepare(42.0, .absolute(1.0))
        
        XCTAssertEqual(defaultData.duration?.seconds, 1.0)
    }
    
    func testInstantMotion() {
        let motion = Instant<Double>(100.0)
        let data = motion.anyMotion.prepare(0.0, nil)
        
        XCTAssertEqual(data.duration?.seconds, 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.0), 100.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 100.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testSideEffectMotion() {
        var actionExecuted = false
        let motion = SideEffect<Double> { actionExecuted = true }
        let data = motion.anyMotion.prepare(42.0, nil)
        
        XCTAssertEqual(data.duration?.seconds, 0.0)
        
        // Test side effects
        actionExecuted = false
        guard let sideEffects = data.sideEffects else {
            XCTFail("Side effects should be defined")
            return
        }
        
        // Range that doesn't include 1.0
        let effects1 = sideEffects(0.0...0.5)
        XCTAssertTrue(effects1.isEmpty)
        
        // Range that includes 1.0
        let effects2 = sideEffects(0.5...1.0)
        XCTAssertEqual(effects2.count, 1)
        if !effects2.isEmpty {
            effects2[0](42.0)
        }
        XCTAssertTrue(actionExecuted)
    }
    
    func testSideEffectWithMotion() {
        var capturedValue: Double?
        let motion = SideEffect<Double> { value in capturedValue = value }
        let data = motion.anyMotion.prepare(42.0, nil)
        
        // SideEffect should not execute at t=0
        _ = data.lerp(42.0, 0.0)
        XCTAssertNil(capturedValue)
        
        // Test side effects
        capturedValue = nil
        guard let sideEffects = data.sideEffects else {
            XCTFail("Side effects should be defined")
            return
        }
        
        let effects = sideEffects(0.5...1.0)
        if !effects.isEmpty {
            effects[0](99.0)
        }
        XCTAssertEqual(capturedValue, 99.0)
    }
    
    // MARK: - Composite Motion Tests
    
    func testSequentialMotion() {
        let motion = Sequential<Double> {
            To(50.0).duration(1.0)
            To(100.0).duration(1.0)
        }
        
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be the sum of individual durations
        XCTAssertEqual(data.duration?.seconds, 2.0)
        
        // First half of the animation
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.25), 25.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        
        // Second half of the animation
        XCTAssertEqual(data.lerp(0.0, 0.75), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testSequentialWithUnevenDurations() {
        let motion = Sequential<Double> {
            To(25.0).duration(1.0)
            To(100.0).duration(3.0)
        }
        
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be the sum of individual durations
        XCTAssertEqual(data.duration?.seconds, 4.0)
        
        // First quarter of the animation (first motion)
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.125), 12.5)
        XCTAssertEqual(data.lerp(0.0, 0.25), 25.0)
        
        // Remaining three-quarters (second motion)
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.75), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testSequentialWithRelativeDurations() {
        let motion = Sequential<Double> {
            To(25.0).duration(.relative(0.25))
            To(100.0)
        }
        
        let data = motion.anyMotion.prepare(0.0, .absolute(4.0))
        
        // Duration should match the explicit duration
        XCTAssertEqual(data.duration?.seconds, 4.0)
        
        // First quarter of the animation (first motion)
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.125), 12.5)
        XCTAssertEqual(data.lerp(0.0, 0.25), 25.0)
        
        // Remaining three-quarters (second motion)
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.75), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testSequentialWithRelativeAndAbsoluteDurations() {
        let motion = Sequential<Double> {
            To(25.0).duration(.relative(0.25))
            To(100.0).duration(3)
        }

        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should match the explicit duration
        XCTAssertEqual(data.duration?.seconds, 4.0)
        
        // First quarter of the animation (first motion)
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.125), 12.5)
        XCTAssertEqual(data.lerp(0.0, 0.25), 25.0)
        
        // Remaining three-quarters (second motion)
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.75), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testParallelMotion() {
        // Test with a simple struct
        struct TestStruct {
            var x: Double
            var y: Double
        }
        
        let motion = Parallel<TestStruct>()
            .x { To(100.0) }
            .y { To(200.0) }
        
        let data = motion.anyMotion.prepare(TestStruct(x: 0.0, y: 0.0), .absolute(1.0))
        
        // Test values at different points
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 0.0).x, 0.0)
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 0.0).y, 0.0)
        
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 0.5).x, 50.0)
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 0.5).y, 100.0)
        
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 1.0).x, 100.0)
        XCTAssertEqual(data.lerp(TestStruct(x: 0.0, y: 0.0), 1.0).y, 200.0)
    }
    
    func testParallelWithDictionary() {
        let initialDict: [String: Double] = ["x": 0.0, "y": 0.0]
        
        let motion = Parallel<[String: Double]> { key in
            if key == "x" {
                To(100.0)
            } else {
                To(200.0)
            }
        }
        
        let data = motion.anyMotion.prepare(initialDict, Duration.absolute(1.0))
        
        // Test values at different points
        let result0 = data.lerp(initialDict, 0.0)
        XCTAssertEqual(result0["x"], 0.0)
        XCTAssertEqual(result0["y"], 0.0)
        
        let result05 = data.lerp(initialDict, 0.5)
        XCTAssertEqual(result05["x"], 50.0)
        XCTAssertEqual(result05["y"], 100.0)
        
        let result1 = data.lerp(initialDict, 1.0)
        XCTAssertEqual(result1["x"], 100.0)
        XCTAssertEqual(result1["y"], 200.0)
    }
    
    func testParallelWithArray() {
        let initialArray: [Double] = [0.0, 10.0, 20.0]
        
        let motion = Parallel<[Double]> { index in
            To(Double(index) * 100.0)
        }
    
        let data = motion.anyMotion.prepare(initialArray, .absolute(1.0))
        
        // Test values at different points
        let result0 = data.lerp(initialArray, 0.0)
        XCTAssertEqual(result0, [0.0, 10.0, 20.0])
        
        let result05 = data.lerp(initialArray, 0.5)
        XCTAssertEqual(result05, [0.0, 55.0, 110.0])
        
        let result1 = data.lerp(initialArray, 1.0)
        XCTAssertEqual(result1, [0.0, 100.0, 200.0])
    }
    
    func testFromMotion() {
        let motion = From<Double>(50.0) {
            To(100.0)
        }
        
        let data = motion.anyMotion.prepare(0.0, .absolute(1.0))
        
        XCTAssertEqual(data.lerp(0.0, 0.0), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    // MARK: - Repeat and AutoReverse Tests
    
    func testRepeatMotion() {
        let motion = To<Double>(100.0).duration(1.0).repeat(3)
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be 3x the original
        XCTAssertEqual(data.duration?.seconds, 3.0)
        
        // First repeat
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 1/6.0), 50.0)
        XCTAssertEqual(data.lerp(0.0, 1/3.0), 0.0)
        
        // Second repeat
        XCTAssertEqual(data.lerp(0.0, 1/3.0 + 0.001), 0.0, accuracy: 1.0) // Just after first repeat
        XCTAssertEqual(data.lerp(0.0, 0.5), 50.0)
        XCTAssertEqual(data.lerp(0.0, 2/3.0), 0.0)
        
        // Third repeat
        XCTAssertEqual(data.lerp(0.0, 2/3.0 + 0.001), 0.0, accuracy: 1.0) // Just after second repeat
        XCTAssertEqual(data.lerp(0.0, 5/6.0), 50.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    func testZeroRepeatMotion() {
        let motion = To<Double>(0.0, 100.0).duration(1.0).repeat(0)
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be 0
        XCTAssertEqual(data.duration?.seconds, 0.0)
        
        // Value should not change
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 0.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 0.0)
    }
    
    func testAutoReverseMotion() {
        let motion = To<Double>(100.0).duration(1.0).autoreverse()
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be 2x the original
        XCTAssertEqual(data.duration?.seconds, 2.0)
        
        // Forward part
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.25), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 100.0)
        
        // Reverse part
        XCTAssertEqual(data.lerp(0.0, 0.75), 50.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 0.0)
    }
    
    func testAutoReverseWithRepeat() {
        let motion = To<Double>(100.0).duration(1.0).autoreverse().repeat(2)
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Duration should be 4x the original (2x for autoreverse, 2x for repeat)
        XCTAssertEqual(data.duration?.seconds, 4.0)
        
        // First autoreverse cycle
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.125), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.25), 100.0)
        XCTAssertEqual(data.lerp(0.0, 0.375), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 0.0)
        
        // Second autoreverse cycle
        XCTAssertEqual(data.lerp(0.0, 0.625), 50.0)
        XCTAssertEqual(data.lerp(0.0, 0.75), 100.0)
        XCTAssertEqual(data.lerp(0.0, 0.875), 50.0)
        XCTAssertEqual(data.lerp(0.0, 1.0), 0.0)
    }
    
    // MARK: - Duration Tests
    
    func testDurationModification() {
        // Test explicit duration
        let motion1 = To<Double>(100.0).duration(2.0)
        let data1 = motion1.prepare(0.0, .absolute(1.0))
        
        XCTAssertEqual(data1.duration?.seconds, 2.0)
        
        // Test relative duration
        let motion2 = To<Double>(100.0).duration(.relative(0.5))
        let data2 = motion2.prepare(0.0, .absolute(2.0))
        
        XCTAssertEqual(data2.duration?.relative, 0.5)
    }
    
    func testDurationArithmetic() {
        // Test duration division
        let duration1 = Duration.absolute(2.0) / 2.0
        XCTAssertEqual(duration1.seconds, 1.0)
        
        let duration2 = Duration.relative(1.0) / 2.0
        XCTAssertEqual(duration2.relative, 0.5)
        
        // Test duration multiplication
        let duration3 = Duration.absolute(1.0) * 2.0
        XCTAssertEqual(duration3.seconds, 2.0)
        
        let duration4 = Duration.relative(0.5) * 2.0
        XCTAssertEqual(duration4.relative, 1.0)
    }
    
    // MARK: - Curve Tests
    
    func testCurveModification() {
        // Define a simple curve that squares the input
        let squareCurve = Curve { t in t * t }
        
        let motion = To<Double>(100.0).curve(squareCurve)
        let data = motion.anyMotion.prepare(0.0, .absolute(1.0))
        
        // With t² curve, motion should be slower at the beginning
        XCTAssertEqual(data.lerp(0.0, 0.0), 0.0)
        XCTAssertEqual(data.lerp(0.0, 0.5), 25.0) // t=0.5 → t²=0.25 → 25.0
        XCTAssertEqual(data.lerp(0.0, 0.7), 49.0, accuracy: 0.01) // t=0.7 → t²=0.49 → 49.0
        XCTAssertEqual(data.lerp(0.0, 1.0), 100.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyParallelMotion() {
        let motion = Parallel<Double>()
        let data = motion.anyMotion.prepare(42.0, .absolute(1.0))
        
        XCTAssertEqual(data.duration?.seconds, 1.0)
        XCTAssertEqual(data.lerp(42.0, 0.0), 42.0)
        XCTAssertEqual(data.lerp(42.0, 1.0), 42.0)
    }
    
    func testOutOfRangeTime() {
        let motion = To<Double>(100.0)
        let data = motion.anyMotion.prepare(0.0, .absolute(1.0))
        
        // Test negative time
        XCTAssertEqual(data.lerp(0.0, -0.5), -50)
        
        // Test time greater than 1
        XCTAssertEqual(data.lerp(0.0, 1.5), 150.0)
    }
    
    func testComplexNestedMotions() {
        // Create a complex nested motion combining various types
        let motion = Sequential<Double> {
            From(10.0) { To(50.0) }.duration(1.0)
            
            Parallel<Double>()
                .at(\.self) {
                    To(100.0).autoreverse()
                }
                .duration(2.0)
            
            SideEffect<Double> { print("SideEffect executed") }
            
            Wait<Double>(.absolute(1.0))
            
            To(0.0).duration(1.0).repeat(2)
        }
        
        let data = motion.anyMotion.prepare(0.0, nil)
        
        // Total duration should be 1 + 2 + 0 + 1 + 2 = 6
        XCTAssertEqual(data.duration?.seconds, 6.0)
        
        // Test at various points along the timeline
        
        // First segment: From 10 to 50 (t=0.0 to t=1/6)
        XCTAssertEqual(data.lerp(0.0, 0.0), 10.0)
        XCTAssertEqual(data.lerp(0.0, 1/12.0), 30.0)
        XCTAssertEqual(data.lerp(0.0, 1/6.0), 50.0)
        
        // Second segment: Parallel with autoreverse (t=1/6 to t=1/2)
        XCTAssertEqual(data.lerp(0.0, 1/6.0 + 0.001), 50.0, accuracy: 0.5)
        XCTAssertEqual(data.lerp(0.0, 1/4.0), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1/3.0), 100.0)
        XCTAssertEqual(data.lerp(0.0, 5/12.0), 75.0)
        XCTAssertEqual(data.lerp(0.0, 1/2.0), 50.0)
        
        // Third segment: SideEffect (t=1/2 to t=1/2, zero duration)
        // Fourth segment: Wait (t=1/2 to t=2/3)
        XCTAssertEqual(data.lerp(0.0, 1/2.0 + 0.001), 50.0, accuracy: 0.1)
        XCTAssertEqual(data.lerp(0.0, 7/12.0), 50.0)
        XCTAssertEqual(data.lerp(0.0, 2/3.0), 50.0)
        
        // Fifth segment: To 0 repeated twice (t=2/3 to t=1.0)
        XCTAssertEqual(data.lerp(0.0, 2/3.0 + 0.001), 50.0, accuracy: 0.5)
        XCTAssertEqual(data.lerp(0.0, 3/4.0), 25.0, accuracy: 0.5)
        XCTAssertEqual(data.lerp(0.0, 5/6.0), 50.0, accuracy: 0.5)
        XCTAssertEqual(data.lerp(0.0, 11/12.0), 25.0, accuracy: 0.5)
        XCTAssertEqual(data.lerp(0.0, 1.0), 0.0, accuracy: 0.5)
    }

    func testStepsMotion() {
           // Test with Double values
           let doubleMotion = Steps<Double>(10.0, 20.0, 30.0, 40.0)
           let doubleData = doubleMotion.anyMotion.prepare(0.0, .absolute(1.0))
           
           // At t=0, we should get the initial value
           XCTAssertEqual(doubleData.lerp(0.0, 0.0), 0.0)
           
           // We have 5 values total including the initial value, so we should step at t=0.2, 0.4, 0.6, 0.8
           XCTAssertEqual(doubleData.lerp(0.0, 0.1), 0.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.2), 10.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.3), 10.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.4), 20.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.5), 20.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.6), 30.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.7), 30.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.8), 40.0)
           XCTAssertEqual(doubleData.lerp(0.0, 0.9), 40.0)
           XCTAssertEqual(doubleData.lerp(0.0, 1.0), 40.0)
           
           // Test with a different initial value
           XCTAssertEqual(doubleData.lerp(5.0, 0.0), 5.0)
           XCTAssertEqual(doubleData.lerp(5.0, 0.2), 10.0)
           
           // Test with a struct containing multiple values
           struct TestPoint {
               var x: Int
               var y: Int
           }
           
           let points = [
               TestPoint(x: 10, y: 10),
               TestPoint(x: 20, y: 20),
               TestPoint(x: 30, y: 30)
           ]
           
           let pointMotion = Steps<TestPoint>(points)
           let pointData = pointMotion.anyMotion.prepare(TestPoint(x: 0, y: 0), .absolute(1.0))
           
           // At t=0, we should get the initial value
           let point0 = pointData.lerp(TestPoint(x: 0, y: 0), 0.0)
           XCTAssertEqual(point0.x, 0)
           XCTAssertEqual(point0.y, 0)
           
           // We have 4 values total including the initial value, so we should step at t=0.25, 0.5, 0.75
           let point25 = pointData.lerp(TestPoint(x: 0, y: 0), 0.25)
           XCTAssertEqual(point25.x, 10)
           XCTAssertEqual(point25.y, 10)
           
           let point5 = pointData.lerp(TestPoint(x: 0, y: 0), 0.5)
           XCTAssertEqual(point5.x, 20)
           XCTAssertEqual(point5.y, 20)
           
           let point75 = pointData.lerp(TestPoint(x: 0, y: 0), 0.75)
           XCTAssertEqual(point75.x, 30)
           XCTAssertEqual(point75.y, 30)
           
           let point1 = pointData.lerp(TestPoint(x: 0, y: 0), 1.0)
           XCTAssertEqual(point1.x, 30)
           XCTAssertEqual(point1.y, 30)
       }
       
}
