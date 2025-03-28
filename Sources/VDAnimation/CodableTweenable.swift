import Foundation

public struct CodableTweenable<Value: Codable>: Tweenable {

    public var value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        try! Self(Value(from: TweenableDecoder(value: .lerp(TweenableEncoder().encode(lhs.value), TweenableEncoder().encode(rhs.value), t))))
    }
}

extension Decodable where Self: Encodable {

    @_disfavoredOverload
    public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
        CodableTweenable<Self>.lerp(CodableTweenable(lhs), CodableTweenable(rhs), t).value
    }
}

enum TweenableCoderValue: Tweenable {

    case double(Double)
    case int(Int)
    case uint(UInt)
    case array([TweenableCoderValue])
    case dictionary([String: TweenableCoderValue])
    case string(String)
    case bool(Bool)
    case `nil`
    case custom(Any, (Any, Double) -> Any)

    static func lerp(_ lhs: TweenableCoderValue, _ rhs: TweenableCoderValue, _ t: Double) -> TweenableCoderValue {
        switch (lhs, rhs) {
        case (let .double(lhs), let .double(rhs)): return .double(.lerp(lhs, rhs, t))
        case (let .int(lhs), let .int(rhs)): return .int(.lerp(lhs, rhs, t))
        case (let .uint(lhs), let .uint(rhs)): return .uint(.lerp(lhs, rhs, t))
        case (let .array(lhs), let .array(rhs)): return .array(.lerp(lhs, rhs, t))
        case (let .dictionary(lhs), let .dictionary(rhs)): return .dictionary(.lerp(lhs, rhs, t))
        case (let .custom(_, lerp), let .custom(rhs, _)):
            return .custom(lerp(rhs, t), lerp)
        default:
            if t > 0.5 {
                return rhs
            } else {
                return lhs
            }
        }
    }
}

// - MARK: Decoder

struct TweenableDecoder: Decoder {

    var value: TweenableCoderValue
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    init(value: TweenableCoderValue, codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.value = value
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        if case .dictionary(let dictionary) = value {
            return KeyedDecodingContainer(
                TweenableKeyedDecodingContainer(codingPath: codingPath, dict: dictionary, userInfo: userInfo)
            )
        }
        
        throw DecodingError.typeMismatch(
            [String: Any].self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected a dictionary but found \(value) instead."
            )
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        if case .array(let array) = value {
            return TweenableUnkeyedDecodingContainer(values: array, codingPath: codingPath, userInfo: userInfo)
        }
        
        throw DecodingError.typeMismatch(
            [Any].self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected an array but found \(value) instead."
            )
        )
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return TweenableSingleValueDecodingContainer(value: value, codingPath: codingPath, userInfo: userInfo)
    }
}

struct TweenableSingleValueDecodingContainer: SingleValueDecodingContainer {
    
    var value: TweenableCoderValue
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    func decodeNil() -> Bool {
        if case .nil = value {
            return true
        }
        return false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        if case let .bool(bool) = value { return bool }
        try error(type)
    }

    func decode(_ type: String.Type) throws -> String {
        if case let .string(string) = value { return string }
        try error(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        if case let .double(double) = value { return double }
        try error(type)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        if case let .double(double) = value { return Float(double) }
        try error(type)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        if case let .int(int) = value { return int }
        try error(type)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        if case let .int(int) = value { return Int8(int) }
        try error(type)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        if case let .int(int) = value { return Int16(int) }
        try error(type)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        if case let .int(int) = value { return Int32(int) }
        try error(type)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        if case let .int(int) = value { return Int64(int) }
        try error(type)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        if case let .uint(int) = value { return int }
        try error(type)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        if case let .uint(int) = value { return UInt8(int) }
        try error(type)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        if case let .uint(int) = value { return UInt16(int) }
        try error(type)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if case let .uint(int) = value { return UInt32(int) }
        try error(type)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if case let .uint(int) = value { return UInt64(int) }
        try error(type)
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if case let .custom(any, _) = value {
            guard let value = any as? T else {
                try error(type)
            }
            return value
        }
        // This would handle custom types by creating a decoder
        let decoder = TweenableDecoder(value: value, codingPath: codingPath, userInfo: userInfo)
        return try T(from: decoder)
    }

    private func error(_ type: Any.Type) throws -> Never {
        throw DecodingError.typeMismatch(
            type,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode \(type) but found \(value) instead."
            )
        )
    }
}

struct TweenableKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var allKeys: [Key] {
        return value.keys.compactMap { Key(stringValue: $0) }
    }
    
    let value: [String: TweenableCoderValue]
    
    init(codingPath: [CodingKey], dict: [String: TweenableCoderValue], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.value = dict
        self.userInfo = userInfo
    }
    
    func contains(_ key: Key) -> Bool {
        return value[key.stringValue] != nil
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        if let val = value[key.stringValue], case .nil = val {
            return true
        }
        return false
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        return try TweenableSingleValueDecodingContainer(value: val, codingPath: codingPath + [key], userInfo: userInfo).decode(type)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        guard case let .dictionary(dict) = val else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected dictionary value for key \(key.stringValue) but found \(val) instead."
            ))
        }
        
        let container = TweenableKeyedDecodingContainer<NestedKey>(codingPath: codingPath + [key], dict: dict, userInfo: userInfo)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        guard let val = value[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "No value associated with key \(key.stringValue)."
            ))
        }
        
        guard case let .array(array) = val else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected array value for key \(key.stringValue) but found \(val) instead."
            ))
        }
        
        return TweenableUnkeyedDecodingContainer(values: array, codingPath: codingPath + [key], userInfo: userInfo)
    }
    
    func superDecoder() throws -> Decoder {
        let superKey = Key(stringValue: "super")!
        return try superDecoder(forKey: superKey)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        guard let val = value[key.stringValue] else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)."
            )
            throw DecodingError.keyNotFound(key, context)
        }
        
        return TweenableDecoder(value: val, codingPath: codingPath + [key])
    }
}

// Need this for the nestedUnkeyedContainer method
struct TweenableUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    let values: [TweenableCoderValue]
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    var count: Int? { return values.count }
    var isAtEnd: Bool { return currentIndex >= (count ?? 0) }
    var currentIndex: Int = 0
    
    init(values: [TweenableCoderValue], codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.values = values
        self.userInfo = userInfo
    }
    
    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end."
            ))
        }
        
        if case .nil = values[currentIndex] {
            currentIndex += 1
            return true
        }
        
        return false
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end."
            ))
        }
        
        let value = values[currentIndex]
        currentIndex += 1

        let container = TweenableSingleValueDecodingContainer(value: value, codingPath: codingPath + [AnyCodingKey(currentIndex)], userInfo: userInfo)
        return try container.decode(type)
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end."
            ))
        }
        
        let value = values[currentIndex]
        currentIndex += 1
        
        guard case let .dictionary(dict) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected dictionary but found \(value) instead."
            ))
        }
        
        let container = TweenableKeyedDecodingContainer<NestedKey>(codingPath: codingPath + [AnyCodingKey(currentIndex)], dict: dict, userInfo: userInfo)
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end."
            ))
        }
        
        let value = values[currentIndex]
        currentIndex += 1
        
        guard case let .array(array) = value else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected array but found \(value) instead."
            ))
        }
        
        return TweenableUnkeyedDecodingContainer(values: array, codingPath: codingPath + [AnyCodingKey(currentIndex)], userInfo: userInfo)
    }

    mutating func superDecoder() throws -> Decoder {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end."
            ))
        }
        
        let value = values[currentIndex]
        currentIndex += 1
        
        return TweenableDecoder(value: value, codingPath: codingPath, userInfo: userInfo)
    }
}

// - MARK: Encoder

struct TweenableEncoder {

    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    func encode<T: Encodable>(_ value: T) throws -> TweenableCoderValue {
        let encoder = _TweenableEncoder(userInfo: userInfo)
        try value.encode(to: encoder)
        return encoder.value
    }
}

class _TweenableEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any]
    
    var value: TweenableCoderValue = .nil
    
    init(userInfo: [CodingUserInfoKey: Any]) {
        self.userInfo = userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = TweenableKeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return TweenableUnkeyedEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return TweenableSingleValueEncodingContainer(encoder: self, codingPath: codingPath)
    }
}

struct TweenableSingleValueEncodingContainer: SingleValueEncodingContainer {
    let encoder: _TweenableEncoder
    var codingPath: [CodingKey]
    
    init(encoder: _TweenableEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        encoder.value = .nil
    }
    
    mutating func encode(_ value: Bool) throws {
        encoder.value = .bool(value)
    }
    
    mutating func encode(_ value: String) throws {
        encoder.value = .string(value)
    }
    
    mutating func encode(_ value: Double) throws {
        encoder.value = .double(value)
    }
    
    mutating func encode(_ value: Float) throws {
        encoder.value = .double(Double(value))
    }
    
    mutating func encode(_ value: Int) throws {
        encoder.value = .int(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        encoder.value = .int(Int(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        encoder.value = .int(Int(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        encoder.value = .int(Int(value))
    }
    
    mutating func encode(_ value: Int64) throws {
        encoder.value = .int(Int(value))
    }
    
    mutating func encode(_ value: UInt) throws {
        encoder.value = .uint(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        encoder.value = .uint(UInt(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        encoder.value = .uint(UInt(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        encoder.value = .uint(UInt(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        encoder.value = .uint(UInt(value))
    }
    
    mutating func encode<T>(_ value: T) throws where T: Encodable {
        if let tweenable = value as? any Tweenable {
            encoder.value = .custom(value, tweenable.lerpTo)
            return
        }
        // For custom encodable types, create a new encoder and encode recursively
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath
        
        try value.encode(to: subEncoder)
        encoder.value = subEncoder.value
    }
}

struct TweenableKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: _TweenableEncoder
    var codingPath: [CodingKey]
    
    private var container: [String: TweenableCoderValue] = [:]
    
    init(encoder: _TweenableEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        container[key.stringValue] = .nil
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        container[key.stringValue] = .bool(value)
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        container[key.stringValue] = .string(value)
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        container[key.stringValue] = .double(value)
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        container[key.stringValue] = .double(Double(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        container[key.stringValue] = .int(value)
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        container[key.stringValue] = .int(Int(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        container[key.stringValue] = .int(Int(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        container[key.stringValue] = .int(Int(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        container[key.stringValue] = .int(Int(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        container[key.stringValue] = .uint(value)
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        container[key.stringValue] = .uint(UInt(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        container[key.stringValue] = .uint(UInt(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        container[key.stringValue] = .uint(UInt(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        container[key.stringValue] = .uint(UInt(value))
        encoder.value = .dictionary(container)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if let tweenable = value as? any Tweenable {
            container[key.stringValue] = .custom(value, tweenable.lerpTo)
            encoder.value = .dictionary(container)
            return
        }
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath + [key]
        
        try value.encode(to: subEncoder)
        container[key.stringValue] = subEncoder.value
        encoder.value = .dictionary(container)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath + [key]
        
        let container = TweenableKeyedEncodingContainer<NestedKey>(encoder: subEncoder, codingPath: codingPath + [key])
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath + [key]
        
        return TweenableUnkeyedEncodingContainer(encoder: subEncoder, codingPath: codingPath + [key])
    }
    
    mutating func superEncoder() -> Encoder {
        let key = Key(stringValue: "super")!
        return superEncoder(forKey: key)
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath + [key]
        return subEncoder
    }
}

struct TweenableUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    let encoder: _TweenableEncoder
    var codingPath: [CodingKey]
    
    private var container: [TweenableCoderValue] = []
    
    var count: Int {
        return container.count
    }
    
    init(encoder: _TweenableEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        container.append(.nil)
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Bool) throws {
        container.append(.bool(value))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: String) throws {
        container.append(.string(value))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Double) throws {
        container.append(.double(value))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Float) throws {
        container.append(.double(Double(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Int) throws {
        container.append(.int(value))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Int8) throws {
        container.append(.int(Int(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Int16) throws {
        container.append(.int(Int(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Int32) throws {
        container.append(.int(Int(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: Int64) throws {
        container.append(.int(Int(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: UInt) throws {
        container.append(.int(Int(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: UInt8) throws {
        container.append(.uint(UInt(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: UInt16) throws {
        container.append(.uint(UInt(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: UInt32) throws {
        container.append(.uint(UInt(value)))
        encoder.value = .array(container)
    }
    
    mutating func encode(_ value: UInt64) throws {
        container.append(.uint(UInt(value)))
        encoder.value = .array(container)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        if let tweenable = value as? any Tweenable {
            container.append(.custom(value, tweenable.lerpTo))
            encoder.value = .array(container)
            return
        }
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath.appending(AnyCodingKey(container.count))
        
        try value.encode(to: subEncoder)
        container.append(subEncoder.value)
        encoder.value = .array(container)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath.appending(AnyCodingKey(container.count))
        
        return KeyedEncodingContainer(TweenableKeyedEncodingContainer<NestedKey>(encoder: subEncoder, codingPath: subEncoder.codingPath))
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath.appending(AnyCodingKey(container.count))
        
        return TweenableUnkeyedEncodingContainer(encoder: subEncoder, codingPath: subEncoder.codingPath)
    }
    
    mutating func superEncoder() -> Encoder {
        let subEncoder = _TweenableEncoder(userInfo: encoder.userInfo)
        subEncoder.codingPath = codingPath.appending(AnyCodingKey(container.count))
        return subEncoder
    }
}

// Helper extension for appending a CodingKey to an array
extension Array where Element == CodingKey {

    func appending(_ key: CodingKey) -> [CodingKey] {
        var result = self
        result.append(key)
        return result
    }
}

struct AnyTween {
    
    private let _lerp: (_ value: Any, _ t: Double) -> Any

    init(_ lerp: @escaping (_: Any, _: Double) -> Any) {
        _lerp = lerp
    }

    func lerp(_ value: Any, _ t: Double) -> Any {
        _lerp(value, t)
    }
}

extension Tweenable {

    var lerpTo: (_ value: Any, _ t: Double) -> Any {
        {
            Self.lerp(self, $0 as! Self, $1)
        }
    }
}
