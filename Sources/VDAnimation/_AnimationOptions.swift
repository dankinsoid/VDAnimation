import Foundation

public struct _AnimationOptions {
    
    fileprivate(set) public static var current = _AnimationOptions()
    
    private var options: [PartialKeyPath<_AnimationOptions>: Any] = [:]
    
    public init() {
    }
    
    public subscript<T>(_ key: KeyPath<_AnimationOptions, T>) -> T? {
        get { options[key] as? T }
        set { options[key] = newValue }
    }
}

public extension _AnimationOptions {
    
    var duration: AnimationDuration {
        get { self[\.duration] ?? .absolute(0.25) }
        set { self[\.duration] = newValue }
    }
}

public func withAnimationOptions<T>(_ modify: (inout _AnimationOptions) -> Void, operation: () throws -> T) rethrows -> T {
    let initial = _AnimationOptions.current
    var current = initial
    modify(&current)
    _AnimationOptions.current = current
    let result = try operation()
    _AnimationOptions.current = initial
    return result
}

public func withAnimationOptions<T, R>(_ keyPath: WritableKeyPath<_AnimationOptions, T>, _ value: T, operation: () throws -> R) rethrows -> R {
    try withAnimationOptions {
        $0[keyPath: keyPath] = value
    } operation: {
        try operation()
    }
}
