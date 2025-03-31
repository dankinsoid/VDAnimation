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
        VStack {
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
                        .end(arcSize) // animate .end property of the state
                        .curve(.easeIn)
                    To(Tween(1 - arcSize, 1.0)) // animate the whole state
                        .duration(.relative((1 - arcSize) / (1 + arcSize)))
                    Parallel()
                        .start(1.0 - 0.01) // animate .start property of the state
                        .curve(.easeOut)
                }
                .duration(1)
            }
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
        VStack {
            WithMotion(_values) { values in
                HStack(spacing: 12) {
                    ForEach(values, id: \.self) { value in
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .offset(y: value)
                        
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue)
            } motion: {
                Parallel { index in
                    To(-10)
                        .duration(0.3)
                        .curve(.easeInOut)
                        .autoreverse()
                        .delay(.relative(Double(index) * 0.2))
                }
            }
        }
        .onAppear {
            $values.play(repeat: true)
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
                  .fill(Color(hue: progress / 5, saturation: 1, brightness: 1))
                  .frame(width: 100, height: 100)
                  .scaleEffect(Tween(0.001, 2).lerp(progress))
                  .rotationEffect(.degrees(progress * 360))
            } motion: {
                To(1.0).duration(2.0).curve(.spring())
            }

            Slider(value: _animation.$progress, in: 0...1)

            HStack {
                Button("Play") { $animation.play(from: 0) }
                Button("Pause") { $animation.pause() }
                Button("Reverse") { $animation.reverse() }
            }
        }
    }
}
```

### UIKit CADisplayLink wrapper

```swift
struct UIKitExample: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIKitExampleView {
        UIKitExampleView()
    }

    func updateUIView(_ uiView: UIKitExampleView, context: Context) {
    }
}

final class UIKitExampleView: UIView {

    let label = UILabel()
    
    struct Value {
        
        var amount: Int = 0
        var color: UIColor = .systemRed
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        
        backgroundColor = .white
        addSubview(label)
        label.font = .monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -100),
             label.centerYAnchor.constraint(equalTo: centerYAnchor)]
        )

        motionDisplayLink(Value()) { [label] value in
            label.text = "\(value.amount) USD"
            label.textColor = value.color
        } motion: {
            Sequential {
                Parallel()
                    .amount(1000)
                    .color(.systemGreen)
                    .delay(.relative(0.2))
                    .duration(2)
            }
        }
        .play()
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

