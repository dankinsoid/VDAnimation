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
  UIViewAnimate {
    self.imageHeightContraint.constant = 50
    self.view.layoutIfNeeded()
  }
}
.curve(.easeInOut)
.duration(3)
.start()
```
## Usage
TODO

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
