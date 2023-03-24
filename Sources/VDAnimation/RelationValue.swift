import Foundation

public typealias AnimationDuration = RelationValue<TimeInterval>

public enum RelationValue<Value> {
    
    case absolute(Value)
    case relative(Double)
    
    public var relative: Double? {
        switch self {
        case .absolute:
            return nil
        case .relative(let double):
            return double
        }
    }
    
    public var absolute: Value? {
        switch self {
        case .absolute(let value):
            return value
        case .relative:
            return nil
        }
    }
}

extension RelationValue: ExpressibleByFloatLiteral where Value == Double {
    
    public init(floatLiteral value: Double) {
        self = .absolute(value)
    }
}


extension RelationValue: ExpressibleByIntegerLiteral where Value == Double {
    
    public init(integerLiteral value: Int) {
        self = .absolute(Double(value))
    }
}

extension RelationValue: Equatable where Value: Equatable {
}

extension RelationValue: Hashable where Value: Hashable {
}

extension RelationValue: Decodable where Value: Decodable {
}

extension RelationValue: Encodable where Value: Encodable {
}

public func / <T: BinaryFloatingPoint>(_ lhs: RelationValue<T>, _ rhs: T) -> RelationValue<T> {
    switch lhs {
    case .absolute(let value):
        return .absolute(value / rhs)
        
    case .relative(let double):
        return .relative(double / Double(rhs))
    }
}

public func * <T: BinaryFloatingPoint>(_ lhs: RelationValue<T>, _ rhs: T) -> RelationValue<T> {
    switch lhs {
    case .absolute(let value):
        return .absolute(value * rhs)
        
    case .relative(let double):
        return .relative(double * Double(rhs))
    }
}

public func * <T: BinaryFloatingPoint>(_ lhs: T, _ rhs: RelationValue<T>) -> RelationValue<T> {
    rhs * lhs
}
