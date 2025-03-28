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
struct CircleState {
    var position: CGPoint
    var scale: CGFloat
    var color: Color
}

struct CircleAnimation: View {
    @MotionState private var state = CircleState(
        position: .zero,
        scale: 1.0,
        color: .blue
    )
    
    var body: some View {
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
                    .color { To(.green) }
                    .duration(0.5)
                
                // Finally animate everything back
                Parallel()
                    .position { To(CGPoint.zero) }
                    .scale { To(1.0) }
                    .color { To(.blue) }
                    .duration(1.0)
            }
        }
        .onAppear {
           $state.play()
        }
    }
}
```

### Animating Collections

```swift
struct BarChartAnimation: View {

    @MotionState private var values: [CGFloat] = [0.2, 0.5, 0.8, 0.3]
    
    var body: some View {
        WithMotion(_values) { values in
            HStack(spacing: 10) {
                ForEach(values.indices, id: \.self) { index in
                    Rectangle()
                        .fill(.blue)
                        .frame(height: values[index] * 200)
                }
            }
        } motion: {
            // Animate each bar independently
            Parallel { index in
                To(values[index] * 1.5).duration(0.5)
            }
            .autoreverse()
            .repeat(2)
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
        Rectangle()
            .frame(width: 50, height: 50)
            .offset(x: value.x, y: value.y)
            .withMotion(_value) { _, value in
                Rectangle()
                    .frame(width: 50, height: 50)
                    .offset(x: value.x, y: value.y)
            } motion: {
                To(CustomType(x: 100, y: 100)).duration(1.0)
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

            Slider(value: $controller.currentProgress, in: 0...1)

            HStack {
                Button("Play") { controller.play() }
                Button("Pause") { controller.pause() }
                Button("Reverse") { controller.reverse() }
            }
        }
    }
}
```

### Advanced Composition

```swift
struct AdvancedAnimation: View {

    @MotionState private var state = Props(
        position: CGPoint.zero,
        scale: 1.0,
        rotation: Angle.zero
    )
    
    var body: some View {
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

