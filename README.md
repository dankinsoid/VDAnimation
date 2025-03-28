# VDAnimation

[![CI Status](https://img.shields.io/travis/dankinsoid/VDAnimation.svg?style=flat)](https://travis-ci.org/dankinsoid/VDAnimation)

## Declarative Animations for SwiftUI

VDAnimation provides a powerful, declarative way to create complex animations in SwiftUI with minimal code. Compose animations sequentially, in parallel, with custom timing and curves.

## Features

- 🎭 Declarative animation composition
- ⏱ Precise timing control
- 🔄 Sequence and parallel animations
- 🎚 Interactive animation control
- 🏗 Built-in support for custom value interpolation

## Examples

### Animating Complex Types

```swift
struct CircleAnimation: View {

    @MotionState private var state = CircleState(
        position: .zero,
        scale: 1.0,
        color: .blue
    )

    var body: some View {
        VStack {
            WithMotion(_state) {  value in
                Circle()
                    .fill(value.color)
                    .frame(width: 100, height: 100)
                    .scaleEffect(value.scale)
                    .position(value.position)
            } motion: {
                Sequential {
                    // First animate position and color in parallel
                    Parallel()
                        .position { To(CGPoint(x: 200, y: 200)) }
                        .color { To(.red) }
                        .duration(1.0)
                    
                    // Then animate scale and color together
                    Parallel()
                        .scale { To(1.5) }
                        .color { To(.blue) }
                        .duration(0.5)
                    
                    // Finally animate everything back
                    Parallel()
                        .position { To(.zero) }
                        .scale { To(1.0) }
                        .color { To(.green) }
                        .duration(1.0)
                }
            }
            Button("Play") {
                $state.play(from: 0)
            }
        }
    }
}
```

### Animating Collections

```swift
struct DotsAnimation: View {

    @MotionState private var values: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        VStack {
            Spacer()
            WithMotion(_values) { values in
                HStack(spacing: 20) {
                    ForEach(values, id: \.self) { value in
                        Circle()
                            .fill(.blue)
                            .frame(width: 30, height: 30)
                            .offset(y: value)
                        
                    }
                }
            } motion: {
                Parallel { index in
                    To(-50)
                        .duration(0.3)
                        .autoreverse()
                        .delay(Double(index) * 0.2)
                }
                .delay(0.3)
            }
            Spacer()
            Button("Play") {
                $values.play(from: 0, repeat: true)
            }
        }
    }
}
```

### Custom Value Interpolation

```swift
@Tweenable
struct CustomType {
    var x: CGFloat
    var y: CGFloat
}

struct CustomAnimation: View {

    @MotionState private var value = CustomType(x: 0, y: 0)

    var body: some View {
        VStack {
            WithMotion(_value) { value in
                Rectangle()
                    .frame(width: 50, height: 50)
                    .offset(x: value.x, y: value.y)
            } motion: {
                To(CustomType(x: 100, y: 100)).duration(1.0)
            }
            Button("Play") {
                $value.play(from: 0)
            }
        }
    }
}
```

### Interactive Animation Control

```swift
struct InteractiveAnimation: View {

    @MotionState private var animation = 0.0
    @State private var color: Color = .blue
    
    var body: some View {
        VStack {
            WithMotion(_animation) { progress in
                Circle()
                  .fill(Color(hue: progress, saturation: 1, brightness: 1))
                  .frame(width: 100, height: 100)
                  .scaleEffect(progress * 2)
                  .rotationEffect(.degrees(progress * 360))
            } motion: {
                To(1.0).duration(2.0).curve(.spring())
            }

            Slider(value: _animation.progress, in: 0...1)

            HStack {
                Button("Play") { $animation.play() }
                Button("Pause") { $animation.pause() }
                Button("Reverse") { $animation.reverse() }
            }
        }
    }
}
```

### Advanced Composition

```swift
struct Props {
    var position: CGPoint
    var scale: Double
    var rotation: Angle
}

struct AdvancedAnimation: View {

    @MotionState private var state = Props(
        position: CGPoint.zero,
        scale: 1.0,
        rotation: Angle.zero
    )
    
    var body: some View {
        VStack {
            WithMotion(_state) { state in
                Rectangle()
                    .fill(.purple)
                    .frame(width: 100, height: 100)
                    .position(state.position)
                    .scaleEffect(state.scale)
                    .rotationEffect(state.rotation)
            } motion: {
                Sequential {
                    // Move diagonally
                    Parallel(\.position) {
                        To(CGPoint(x: 200, y: 200))
                    }
                    
                    // Complex transformation
                    Parallel()
                        .scale { To(1.5) }
                        .rotation { To(.degrees(180)) }
                        .duration(1.0)
                    
                    // Bounce back
                    Parallel(\.position) {
                        To(CGPoint(x: 150, y: 150))
                            .duration(0.3)
                            .curve(.easeOut)
                            .autoreverse()
                    }
                }
                .duration(3.0)
            }
            Button("Play") {
                $state.play(from: 0)
            }
        }
    }
}

```

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dankinsoid/VDAnimation.git", from: "2.0.0")
]
```

Or add it directly in Xcode via File > Add Packages...

## License

VDAnimation is available under the MIT license. See the LICENSE file for more info.

