# VDAnimation
[![CI Status](https://img.shields.io/travis/Voidilov/VDCodable.svg?style=flat)](https://travis-ci.org/Voidilov/VDCodable)
[![Version](https://img.shields.io/cocoapods/v/VDCodable.svg?style=flat)](https://cocoapods.org/pods/VDCodable)
[![License](https://img.shields.io/cocoapods/l/VDCodable.svg?style=flat)](https://cocoapods.org/pods/VDCodable)
[![Platform](https://img.shields.io/cocoapods/p/VDCodable.svg?style=flat)](https://cocoapods.org/pods/VDCodable)

## Description
This repository includes some useful tools for `Codable` protocol and data decoding.

## Usage

1. `JSON`

`JSON` enum makes it easy to deal with JSON data.
Use `String`, `Int` subscripts and dynamic member lookup ("dot" syntax) to retrieve a value:
```swift
if let name = json.root.array[0]?.name.string {...}
//or if let name = json["root"]["array"][0]["name"]?.string {...}
```
`JSON` enum uses purely Swift JSON serialization based on [Swift Protobuf](https://github.com/apple/swift-protobuf/tree/master/Sources/SwiftProtobuf) implementation, which is extremely fast.
Confirms to `Codable`.

2. `VDJSONDecoder`

An object that decodes instances of a data type from JSON objects.
Main differences from Foundation `JSONDecoder`:
- Decoding non-string types from quoted values (like "true", "0.0")
- Custom JSON parsing via `(([CodingKey], JSON) -> JSON)` closure
- Purely Swift and faster
3. `VDJSONEncoder`

Purely Swift version of `JSONEncoder`.

4. `URLQueryEncoder` and `URLQueryDecoder`

Encoder and decoder for query strings.
```swift
struct SomeStruct: Codable {
  var title = "Query_string"
  let number = 0
}
let baseURL = URL(string: "https://base.url")!
let value = SomeStruct() 
let url = try? URLQueryEncoder().encode(value, for: baseURL)
//url = "https://base.url?title=Query_string&number=0"
```
5. `DictionaryDecoder` and `DictionaryEncoder`

6. `NSManagedDecodable`, `NSManagedEncodable` and `NSManagedCodable` protocols

Protocols that make your `NSManagedObject` subclasses confirm to `Codable` protocol.

7. `PlainCodingKey` 

Simple `CodingKey` struct.

8. Type reflection for `Decodable` types

```swift
let properties: [String: Any.Type] = Mirror.reflect(SomeType.self)
//or Mirror(SomeType.self).children
``` 
9. Tools for creating custom encoders/decoders

Based on similar logic when writing different encoders/decoders `DecodingUnboxer` and `EncodingBoxer` protocols were implemented.
Examples of usage are all encoders in decoders in this repo.

## Installation
1.  [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'VDCodable'
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
    .package(url: "https://github.com/dankinsoid/VDCodable.git", from: "0.13.0")
    ],
  targets: [
    .target(name: "SomeProject", dependencies: ["VDCodable"])
    ]
)
```
```ruby
$ swift build
```
## Author

Voidilov, voidilov@gmail.com

## License

VDCodable is available under the MIT license. See the LICENSE file for more info.
