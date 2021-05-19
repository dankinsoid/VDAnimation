# VDAnimation

[![CI Status](https://img.shields.io/travis/dankinsoid/VDAnimation.svg?style=flat)](https://travis-ci.org/dankinsoid/VDAnimation)
[![Version](https://img.shields.io/cocoapods/v/VDAnimation.svg?style=flat)](https://cocoapods.org/pods/VDAnimation)
[![License](https://img.shields.io/cocoapods/l/VDAnimation.svg?style=flat)](https://cocoapods.org/pods/VDAnimation)
[![Platform](https://img.shields.io/cocoapods/p/VDAnimation.svg?style=flat)](https://cocoapods.org/pods/VDAnimation)


## Description
This repository provides a new declarative way to describe animations

## Example

```swift
Sequential {
  Parallel {
    someView.ca.frame.origin.y[100]
    someView.ca.backgroundColor[.red].duration(relative: 0.2)
  }
  Parallel {
    someView.ca.transform[CGAffineTransform(rotationAngle: CGFloat.pi / 3)]
    someView.ca.backgroundColor[.white].duration(0.1)
    Sequential {
      someView.ca.backgroundColor[.blue]
      someView.ca.backgroundColor[.green]
    }
  }
  Animate {
    self.imageHeightConstraint.constant = 50
    self.view.layoutIfNeeded()
  }
  TimerAnimation { progress in
  	someLabel.textColor = (UIColor.white...UIColor.red).at(progress)
  }
}
.curve(.easeInOut)
.duration(3)
.start()
```
## Usage
### `Animate`
simple animation, it's initialized by closure
#### UKit
```swift 
Animate {
  ...
}
.duration(0.3)
.start()
```
#### SwiftUI
```swift 
struct SomeView: View {
  let animations = AnimationsStore()
  @State private var someValue: Value
		
  var body: some View {
    VStack {
      Button(Text("Tap")) {
        Sequential {
	  Animate(animations) {
	    $someValue =~ newValue
	  }
	  .duration(0.3)
	  Animate(animations) { progress in
	    someValue = (from...to).at(progress)
	    //progress may be 0 or 1
	    //or any value in 0...1 if animation is interactive
	  }
	  .duration(0.3)
        }
        .start()
      }
    }
    .with(animations)
  }
		
  var example2: some View {
    VStack {
      Slider(value: animations.progressBinding, in: 0...1)
      Button("Play") {
	animations.play()
      }
      Button("Pause") {
	animations.pause()
      }
    }
    .with(animations) {
      Animate(animations) {
	$someValue =~ newValue
      }
      .duration(2)
    }
  }
}
```
### `Sequential`
sequential animations running one after another
```swift 
Sequential {
  Animate { ... }.duration(relative: 0.5)
  Interval(0.1)
  Parallel { ... }
}
.duration(1)
.start()
```
### `Parallel`
parallel animations running simultaneously
```swift 
Parallel {
  Animate { ... }.duration(relative: 0.5)
  Sequential { ... }	
}
.duration(1)
.start()
```
### `Interval`
time interval
```swift 
Interval(1)
```
### `Instant`
any block of code, always zero duration
```swift 
Instant {
  ...
}
```
### `TimerAnimation`
`CADisplayLink` wrapper
```swift 
TimerAnimation { progress in
  ...
}
```

### Interactive
method `.start()` or `.delegate()` returns `AnimationDelegateProtocol` object
#### `AnimationDelegateProtocol`
1. `.isRunning`: `Bool` { get }
2. `.position`: `AnimationPosition` { get nonmutating set }
3. `.options`: `AnimationOptions` { get }
4. `.play(with options: AnimationOptions)`
5. `.pause()`
6. `.stop(at position: AnimationPosition?)`
7. `.add(completion: @escaping (Bool) -> Void)`
8. `.cancel()`

### Modifiers
1. `.duration(TimeInterval)` - sets the animation duration in seconds
2. `.duration(relative: Double)` - sets the animation duration relative to the parent animation in 0...1
3. `.curve(BezierCurve)` - sets the animation curve
4. `.spring(dampingRatio: CGFloat = 0.3)` - sets spring animation curve (only for `Animate`)
5. `.repeat()`, `.repeat(Int)` - repeat animation
5. `.autoreverse()`, `.autoreverse(repeat: Int)` - autoreverse animation
5. `.reversed()` - reversed animation
6. `.ca` - `UIView`, `CALayer` and `View`, `Binding` extension to describe an animation of properties
```swift 
someView.ca.backgroundColor[.white].layer.cornerRadius[8].tintColor[.red].duration(0.3).start()
```

### Transitions
VDAnimation provides easy way to describe `UIViewController` transitions.
VDAnimation also supports transitions like Keynote's `Magic Move` or [`Hero`](https://github.com/HeroTransitions/Hero). It checks the `.transition.id` property on all source and destination views. Every matched view pair is then automatically transitioned from its old state to its new state.
```swift 
viewController.transition.isEnabled = true
viewController.transition.duration = 0.4
viewController.transition.curve = .easeIn
viewController.transition.modifier = .edge(.bottom)
viewController.transition.interactive.disappear = .swipe(to: .bottom)
present(viewController, animated: true)
```
```swift 
fromVc.someView.transition.id = "source"
toVc.someView.transition.id = "source"
fromVc.someView2.transition.modifier = .scale.offset(10)
to.someView2.transition.modifier = .scale.offset(-10)
toVc.transition.isEnabled = true
viewController.transition.interactive.disappear = .swipe(to: .bottom)
present(toVc, animated: true)
```
```swift 
toVc.transition = .pageSheet(from: .bottom)
present(toVc, animated: true)
```

## Installation
1.  [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'VDAnimation'
```
and run `pod update` from the podfile directory first.

2. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.
```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/VDAnimation.git", from: "1.12.0")
  ],
  targets: [
    .target(name: "SomeProject", dependencies: ["VDAnimation"])
  ]
)
```
```ruby
$ swift build
```

## Author

dankinsoid, voidilov@gmail.com

## License

VDAnimation is available under the MIT license. See the LICENSE file for more info.

