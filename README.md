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

### Basic Animation

```swift
struct FadeInView: View {
    @State private var opacity = 0.0
    
    var body: some View {
        Rectangle()
            .fill(.blue)
            .opacity(opacity)
            .withMotion(.init(wrappedValue: opacity)) { _, value in
                Rectangle()
                    .fill(.blue)
                    .opacity(value)
            } motion: {
                To(1.0).duration(1.0).curve(.easeInOut)
            }
            .onAppear {
                opacity = 1.0
            }
    }
}
```

### Complex Sequence

```swift
Sequential {
    // Move right while fading in
    Parallel()
      .offset { To(100) }
      .opacity { To(1.0) }
      .duration(0.5)
    
    // Bounce effect
    To(1.2)
      .duration(0.2)
      .curve(.easeOut)
      .autoreverse()
      .repeat(3)
    
    // Spin and fade out
    Parallel()
      .rotationEffect { To(.degrees(360)) }
      .opacity { To(0.0) }
      .duration(1.0)
}
```

### Interactive Animation Control

```swift
struct InteractiveAnimation: View {
    @StateObject private var controller = AnimationController()
    @State private var color: Color = .blue
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 100, height: 100)
                .scaleEffect(controller.currentProgress * 2)
                .rotationEffect(.degrees(controller.currentProgress * 360))
            
            Slider(value: $controller.currentProgress, in: 0...1)
            
            HStack {
                Button("Play") { controller.play() }
                Button("Pause") { controller.pause() }
                Button("Reverse") { controller.reverse() }
            }
        }
        .withMotion(controller) { _, progress in
            Circle()
                .fill(Color(hue: progress, saturation: 1, brightness: 1))
                .frame(width: 100, height: 100)
                .scaleEffect(progress * 2)
                .rotationEffect(.degrees(progress * 360))
        } motion: {
            To(1.0).duration(2.0).curve(.spring())
        }
    }
}
```

### Advanced Composition

```swift
struct AdvancedAnimation: View {
    @State private var position = CGPoint.zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    
    var body: some View {
        Rectangle()
            .fill(.purple)
            .frame(width: 100, height: 100)
            .withMotion(.init(wrappedValue: position)) { _, pos in
                Rectangle()
                    .fill(.purple)
                    .frame(width: 100, height: 100)
                    .position(pos)
                    .scaleEffect(scale)
                    .rotationEffect(rotation)
            } motion: {
                Sequential {
                    // Move diagonally
                    To(CGPoint(x: 200, y: 200))
                    
                    // Complex transformation
                    Parallel {
                        $0.scale(To(1.5))
                        $0.rotation(To(.degrees(180)))
                    }
                    .duration(1.0)
                    
                    // Bounce back
                    AutoReverse {
                        To(CGPoint(x: 150, y: 150))
                            .duration(0.3)
                            .curve(.easeOut)
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

