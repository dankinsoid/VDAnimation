# VDAnimation Motion Guide

This comprehensive guide demonstrates the capabilities of the VDAnimation library, explaining each motion type, their usage patterns, and examples.

## Table of Contents

- [Basic Concepts](#basic-concepts)
- [Getting Started](#getting-started)
- [Motion Types](#motion-types)
   - [To](#to)
   - [Sequential](#sequential)
   - [Parallel](#parallel)
   - [From](#from)
   - [Wait](#wait)
   - [Instant](#instant)
   - [SideEffect](#sideeffect)
   - [Repeat](#repeat)
   - [AutoReverse](#autoreverse)
   - [Sync](#sync)
   - [Steps](#steps)
   - [TransformTo](#transformto)
- [Common Modifiers](#common-modifiers)
- [Animation Curves](#animation-curves)
- [Integration with SwiftUI](#integration-with-swiftui)
- [Working with UIKit](#working-with-uikit)
- [Advanced Usage](#advanced-usage)

## Basic Concepts

- **Motion**: A type that describes an animation from one value to another
- **MotionState**: A property wrapper that holds an initial value and its animation controller
- **WithMotion**: A SwiftUI view that applies motion animations to its content
- **Tweenable**: A protocol that enables types to be animated by defining interpolation between values

## Getting Started

### Basic SwiftUI Integration

```swift
struct SimpleAnimation: View {
    @MotionState private var scale = 1.0
    
    var body: some View {
        WithMotion(_scale) { value in
            Circle()
                .fill(Color.blue)
                .scaleEffect(value)
                .frame(width: 100, height: 100)
        } motion: {
            To(2.0).duration(1.0).curve(.easeInOut).autoreverse()
        }
        .onAppear {
            $scale.play(repeat: true)
        }
    }
}
```

## Motion Types

### To

The `To` motion animates a value towards a target value or multiple target values.

```swift
To(targetValue)
To(value1, value2, value3)
To(value1, value2, value3, lerp: { $0 * $1 })
To(arrayOfValues)
To(arrayOfValues, lerp: { $0 * $1 })
```

#### Parameters

- `targetValue`: The final value to animate towards
- `values`: Multiple values to animate through in sequence
- `lerp`: A custom function that interpolates between values

### Sequential

The `Sequential` motion runs multiple animations one after another in sequence.

```swift
Sequential {
    To(1.0).duration(0.3)
    Wait(0.5)
    To(0.0).duration(0.3)
}
```

### Parallel

The `Parallel` motion runs multiple animations simultaneously. It provides three main approaches for animating different aspects of a value.

#### 1. Animating by KeyPaths

For struct properties using keypath syntax.

```swift
// Method 1: Using KeyPath builder
Parallel<CGSize>() // Generic type can be omitted in most cases.
    .at(\.width) { To(100.0).curve(.easeOut) }
    .at(\.height) { To(200.0) }

// Method 2: Using dynamic member lookup and MotionBuilder 
Parallel<CGSize>()
    .width {
        To(100.0).duration(0.5).curve(.easeOut)
    }
    
// Method 3: Using dynamic member lookup and callAsFunction shorthand
Parallel<CGSize>()
    .width(100, 200, 300)  // Shorthand for .at(\.width) { To(100, 200, 300) }
```

#### 2. Animating by Collection Indices

For mutable collections elements using index-based access.

```swift
Parallel<[Double]> { index in
    // index is the position in the array
    To(10.0).delay(.relative(Double(index) * 0.1))
}
```

#### 3. Animating by Dictionary Keys

For dictionary elements using key-based access.

```swift
Parallel<[String: CGFloat]> { key in
    if key == "opacity" {
        To(1.0).duration(0.3)
    } else if key == "scale" {
        To(1.2).duration(0.5).curve(.easeOut)
    } else {
        0 // Motion builder allows just put the value to animate. Same as To(0)
    }
}
```

### From

The `From` motion sets a specific starting value for an animation.

```swift
From(startValue) {
    To(1.0).duration(0.3)
}
```

### Wait

The `Wait` motion pauses the animation for a specified duration or all available time.

```swift
Wait(1.0)

Wait(.relative(0.5))

Sequential {
    To(1.0).duration(0.3)
    Wait()  // Pause for 0.4 seconds
    To(0.0).duration(0.3)
}
.duration(1.0)
```

#### Parameters

- `duration`: Duration to wait, can be absolute or relative. Optional parameter. When not provided, the duration will be the remaining time of the parent motion.

### Instant

The `Instant` motion immediately changes to a specified value without animation.

```swift
Sequential {
    To(0.5).duration(0.3)
    Instant(1.0)  // Jump immediately to 1.0
    Wait(0.2)
    To(0.0).duration(0.3)
}
```

### SideEffect

The `SideEffect` motion executes a closure at a specific point in the animation.

```swift
SideEffect { 
    FeedbackManager.triggerHapticFeedback()
}

SideEffect { value in
    // Action that receives the current value
}

Sequential {
    To(0.5).duration(0.3)
    SideEffect { 
        hapticFeedback()
    }
    To(1.0).duration(0.3)
}
```

**Note**: SideEffect is executed asynchronously.

### Repeat

The `Repeat` motion repeats an animation a specified number of times.

```swift
// Method 1: Using modifier
To(1.0).duration(0.5).repeat(3)

// Method 2: Using wrapper
Repeat(3) {
    Sequential {
        To(1.2).duration(0.15)
        To(0.9).duration(0.15)
    }
}
```

### AutoReverse

The `AutoReverse` motion plays an animation forward and then in reverse (ping-pong effect).

```swift
// Method 1: Using modifier
To(1.2).curve(.easeOut).autoreverse()

// Method 2: Using wrapper
AutoReverse {
    To(1.2).duration(0.5).curve(.easeOut)
}
```
### Sync

The `Sync` motion synchronizes animation with system time for continuous animations that should remain smooth even if the UI temporarily freezes.


```swift
// Method 1: Using modifier
To(CGFloat.pi * 2).autoreverse().duration(1.0).sync()

// Method 2: Using wrapper
Sync {
    To(CGFloat.pi * 2).autoreverse().duration(1.0)
}
```

### Steps

The `Steps` motion animates through discrete values with jumps rather than smooth transitions.

```swift
Steps(0.0, 0.3, 0.7, 1.0)
```

### TransformTo

The `TransformTo` motion animates using a transformation function applied to the initial value.

```swift
TransformTo { value in value * 2 }
```

## Common Modifiers

All motion types support the following modifiers:

### Duration

```swift
motion.duration(1.0)  // In seconds
motion.duration(.absolute(1.0))  // Absolute time
motion.duration(.relative(0.5))  // Relative to parent motion
```

**Note**: Duration doesn't guarantee the exact duration of the animation, because the animation may prefer it's own duration. For example, `Instant` motion will always be 0 duration.

### Delay

```swift
motion.delay(0.2)  // Delay in seconds
motion.delay(.relative(0.1))  // Relative delay
```

### Curve

```swift
motion.curve(.linear)
motion.curve(.easeInOut)
motion.curve(.spring(damping: 0.7, velocity: 0.3))
```

## Animation Curves

VDAnimation provides a rich set of animation curves:

### Basic Curves

- `.linear` - Constant speed
- `.easeIn` - Accelerating
- `.easeOut` - Decelerating
- `.easeInOut` - Accelerating then decelerating

### Advanced Curves

- `.cubicEaseIn`, `.cubicEaseOut`, `.cubicEaseInOut` - Cubic easings with more pronounced acceleration
- `.elasticEaseIn`, `.elasticEaseOut` - Elastic effect (overshooting with oscillation)
- `.bounceEaseIn`, `.bounceEaseOut` - Bouncing effect
- `.sineEaseIn`, `.sineEaseOut`, `.sineEaseInOut` - Sine-based easings
- `.backEaseIn`, `.backEaseOut` - Overshooting animation that backs up before/after animating

### Special Curves

- `.step(threshold)` - Step function that jumps at threshold
- `.interval(range)` - Maps to specific range
- `.spring(damping, velocity)` - Spring physics

## Integration with SwiftUI

### MotionState

```swift
@MotionState private var opacity = 0.0
@MotionState private var position = CGPoint.zero
@MotionState private var colors: [Color] = [.red, .green, .blue]

// For types that require custom initialization
@MotionState private var complexState = MyTweenable(initialValue: 0)
```

### WithMotion View

```swift
WithMotion(_state) { value in
    // View using animated value
    Circle()
        .opacity(value)
} motion: {
    // Motion definition
    To(1.0).duration(0.5)
}
```

### Animation Control

```swift
// Start animation
$state.play()  // Play once
$state.play(repeat: true)  // Play repeatedly

// Control
$state.pause()  // Pause animation
$state.reverse()  // Reverse direction
$state.toggle()  // Toggle between play/pause

// Jump to specific progress
$state.progress = 0.5  // Set progress directly
```

## Working with UIKit

VDAnimation also works with UIKit through a `CADisplayLink` wrapper.

```swift
final class UIKitExampleView: UIView {
    let label = UILabel()
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        
        setupUI()
        
        // Start animation
        motionDisplayLink(0) { [weak self] value in
            self?.updateUI(with: value)
        } motion: {
            To(1000).duration(2.0).curve(.easeInOut)
        }
        .play()
    }
}
```

## Advanced Usage

### Custom Tweenables

You can make your own types animatable by conforming to the `Tweenable` protocol:

```swift
// Method 1: Using macro
@Tweenable
struct MyAnimatableType {
    var progress: Double
    var color: Color
}

// Method 2: Manually conform to Tweenable
struct MyAnimatableType: Tweenable {
    var progress: Double
    var color: Color
    
    static func lerp(_ a: MyAnimatableType, _ b: MyAnimatableType, _ t: Double) -> MyAnimatableType {
        MyAnimatableType(
            progress: .lerp(a.progress, b.progress, t),
            color: .lerp(a.color, b.color, t)
        )
    }
}
```
