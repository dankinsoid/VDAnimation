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
struct LoaderAnimation: View {

    @MotionState private var state = Tween(0.0, 0.01)
    private let arcSize = 0.4

    var body: some View {
        WithMotion(_state) { value in
            Circle()
                .trim(from: value.start, to: value.end)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(-.degrees(90), anchor: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green)
        } motion: {
            Sequential {
                Parallel() // Parallel allows to animate properties of the state independently
                    .end(arcSize) // animate .end property of the state
                    .curve(.cubicEaseIn)

                To(Tween(1 - arcSize, 1.0)) // animate the whole state
                    .duration(.relative((1 - arcSize) / (1 + arcSize))) // compute duration to make speed of the animation constant

                Parallel()
                    .start(1.0 - 0.01) // animate .start property of the state
                    .curve(.cubicEaseOut)
            }
            .duration(1)
        }
        .onAppear {
            $state.play(repeat: true)
        }
    }
}
```

### Animating Collections

```swift
struct DotsAnimation: View {

    @MotionState private var values: [CGFloat] = [0, 0, 0]

    var body: some View {
        WithMotion(_values) { values in
            HStack(spacing: 12) {
                ForEach(values, id: \.self) { value in
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(y: value)
                }
            }
        } motion: {
            Parallel { index in // Parallel allows to animate values of collections independently
                To(-10)
                    .duration(0.3)
                    .curve(.easeInOut)
                    .autoreverse()
                    .delay(.relative(Double(index) * 0.2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .onAppear {
            $values.play(repeat: true)
        }
    }
}
```

### Interactive Animation Control

```swift
struct InteractiveAnimation: View {

    @MotionState private var animation = Props()
    @State private var color: Color = .blue
    
    @Tweenable
    struct Props {
        var color: Color = .red
        var angle: Angle = .zero
        var offset: CGFloat = -120
    }
    
    var body: some View {
        VStack(spacing: 30) {
            WithMotion(_animation) { props in
                Rectangle()
                    .fill(props.color)
                    .rotationEffect(props.angle, anchor: .center)
                    .offset(x: props.offset)
                    .frame(width: 100, height: 100)
                Slider(value: _animation.$progress, in: 0...1)
                    .padding(.horizontal)
            } motion: {
                To(
                    Props(
                        color: .blue,
                        angle: .degrees(360),
                        offset: 120
                    )
                )
                .duration(2.0)
            }

            HStack {
                if $animation.isAnimating {
                    Button("Pause") { $animation.pause() }
                } else {
                    Button("Play") {
                        if $animation.progress == 1.0 || $animation.progress == 0.0 {
                            $animation.reverse()
                        } else {
                            $animation.play()
                        }
                    }
                }
            }
        }
    }
}
```

### UIKit CADisplayLink wrapper

```swift
motionDisplayLink(Value()) { [label] value in
    label.text = "\(value.amount) USD"
    label.textColor = value.color
} motion: {
    Parallel()
        .amount(1000)
        .color(.systemGreen)
        .delay(.relative(0.2))
        .duration(2)
}
.play()
```

## Usage

### [Motion Guide](MOTION_GUIDE.md)

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

