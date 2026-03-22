# VDAnimation

## Declarative Animations for SwiftUI

VDAnimation provides a powerful, declarative way to create complex animations in Swift with minimal code. Compose animations sequentially, in parallel, with custom timing and curves.

## Features

- 🎭 Declarative animation composition
- 🔄 Sequence and parallel animations
- 🎚 Interactive animation control
- 🎯 Side effects
- 🏗 Built-in support for custom value interpolation
- 📱 Working on iOS 13 and macOS 10.15 or later
- 🧩 SwiftUI and UIKit support

## Examples

### Animating Complex Types

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/loader.gif?raw=true" width="100">

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
                Parallel()
                    .end(arcSize) // animate .end property to 0.4
                    .curve(.cubicEaseIn)
    
                To(Tween(1 - arcSize, 1.0)) // animate the whole state to (0.6, 1.0)
                    .duration(.relative((1 - arcSize) / (1 + arcSize))) // compute duration to keep movement speed constant
    
                Parallel()
                    .start(1.0 - 0.01) // animate .start property to 0.99
                    .curve(.cubicEaseOut)
            }
            .duration(1)
            .sync() // synchronize all loaders across the app
        }
        .onAppear {
            $state.play(repeat: true)
        }
    }
}
```

### Animating Collections

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/dots.gif?raw=true" width="100">

```swift
struct DotsAnimation: View {

    @MotionState private var values: [CGFloat] = [0, 0, 0]

    var body: some View {
        WithMotion(_values) { values in
            HStack(spacing: 12) {
                ForEach(Array(values.enumerated()), id: \.offset) { value in
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(y: value.element)
                }
            }
        } motion: {
            Parallel { index in
                To(-10)
                    .duration(0.3)
                    .curve(.easeInOut)
                    .autoreverse()
                    .delay(.relative(Double(index) / Double(values.count * 2 - 1))) // delay based on index
            }
            .sync() // synchronize all loaders across the app
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .onAppear {
            $values.play(repeat: true)
        }
    }
}
```

### Animating Paths Morphing

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/path.gif?raw=true" width="100">

```swift
struct PathAnimation: View {
    @MotionState var path: Path = Self.heartPath

    var body: some View {
        VStack {
            WithMotion(_path) { path in
                path.fill()
            } motion: {
                Sequential {
                    Wait()
                    To(Self.dropPath)
                    Wait()
                    To(Self.starPath)
                    Wait()
                    To(Self.heartPath)
                }
                .duration(2)
            }
            .frame(width: 100, height: 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
        }
        .onAppear {
            $path.play(repeat: true)
        }
    }
}
```

### Interactive Animation Control

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/interactive.gif?raw=true" height="120">

```swift
struct InteractiveAnimation: View {

    @MotionState private var animation = Props()
    
    @Tweenable
    struct Props {
        var color: Color = .red
        var angle: Angle = .zero
        var offset: CGFloat = -120
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WithMotion(_animation) { props in
                VStack(spacing: 10) {
                    Rectangle()
                        .fill(props.color)
                        .rotationEffect(props.angle, anchor: .center)
                        .offset(x: props.offset)
                        .frame(width: 100, height: 100)
                    Slider(value: _animation.$progress, in: 0...1)
                        .padding(.horizontal)
                }
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
```

### Complex movement

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/movement.gif?raw=true" height="100">

```swift
struct ComplexMovement: View {

    @MotionState var location = CGPoint(x: -100, y: 0)

    var body: some View {
        Circle()
            .fill(Color.white)
            .withMotion(_location) {
                $0.position($1)
            } motion: {
                Lerp { t in
                    CGPoint(
                        x: cos(Double.lerp(0, .pi * 2, t)) * 100,
                        y: sin(Double.lerp(0, .pi * 6, t)) * 40
                    )
                }
                .duration(2)
            }
            .offset(y: 10)
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .onTapGesture {
                if $location.isAnimating {
                    $location.stop()
                } else {
                    $location.play(repeat: true)
                }
            }
    }
}
```

### UIKit CADisplayLink wrapper

<img src="https://github.com/dankinsoid/Resources/blob/main/VDAnimation/uikit.gif?raw=true" height="80">

```swift
motionDisplayLink(Value(amount: 0, color: .systemRed)) { [label] value in
    label.text = "\(value.amount) USD"
    label.textColor = value.color
} motion: {
    To(Value(amount: 1000, color: .systemGreen))
        .delay(.relative(0.2))
        .delayAfter(.relative(0.2))
        .duration(2)
}
.play()
```

## Color Interpolation

VDAnimation interpolates colors in perceptually uniform color spaces for natural-looking transitions.

| Mode | Description | Speed |
|------|-------------|-------|
| `displayP3` | Linear in gamma-encoded Display P3. Matches UIKit `CGGradient`. | Fastest |
| `okLAB` (default) | Perceptually uniform, Cartesian. Matches SwiftUI `LinearGradient`. | Fast |
| `okLCH` | Adaptive OKLCH/OKLab blend based on chroma difference. Best for static gradients. | Moderate |

`okLCH` uses OKLCH hue path when chromas are similar and shifts toward OKLab when they diverge — avoiding artifacts from the polar coordinate singularity at low chroma.

```swift
// Set globally
ColorInterpolationType.default = .okLCH
```

## Usage

### [Motion Guide](MOTION_GUIDE.md)

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dankinsoid/VDAnimation.git", from: "2.3.0")
]
```

Or add it directly in Xcode via File > Add Packages...

## License

VDAnimation is available under the MIT license. See the LICENSE file for more info.

