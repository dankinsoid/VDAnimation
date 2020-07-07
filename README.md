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
    someView.ca.frame.origin.y.set(100)
    someView.ca.backgroundColor.set(.red).duration(relative: 0.2)
  }
  Parallel {
    someView.ca.transform.set(CGAffineTransform(rotationAngle: CGFloat.pi / 3))
    someView.ca.backgroundColor.set(.white).duration(0.1)
    Sequential {
      someView.ca.backgroundColor.set(.blue)
      someView.ca.backgroundColor.set(.green)
    }
  }
  Animate {
    self.imageHeightConstraint.constant = 50
    self.view.layoutIfNeeded()
  }
  ForEachFrame { progress in
  	someLabel.textColor = (UIColor.white...UIColor.red).at(progress)
  }
}
.curve(.easeInOut)
.duration(3)
.start()
```
## Usage
#### Basic animations
1. Animate - simple UIKit animation, it's initialized by closure
2. SwiftUIAnimate (beta) - simple SwiftUI animation, it's initialized by closure
3. Sequential - sequential animations running one after another
4. Parallel - parallel animations running simultaneously
5. Interval - time interval
6. WithoutAnimation
7. ForEachFrame

#### Modifiers
1. duration(TimeInterval) - sets the animation duration in seconds
2. duration(relative: Double) - sets the animation duration relative to the parent animation in 0...1
3. curve(BezierCurve) - sets the animation curve
4. spring(dampingRatio: CGFloat = 0.3) - sets spring animation curve (UIViewAnimate)
5. ca - UIView, CALayer and View extension to describe an animation of one property
```swift 
	let animation = someView.ca.anyMutableViewProperty.set(newValue)
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
    .package(url: "https://github.com/dankinsoid/VDAnimation.git", from: "0.1.3")
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

