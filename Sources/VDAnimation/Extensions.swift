import SwiftUI

extension TimeInterval {
    
    public static var defaultAnimationDuration = 0.25
}

extension EnvironmentValues {
    
    private enum AnimationDuration: EnvironmentKey {
        
        static var defaultValue: Double { .defaultAnimationDuration }
    }
    
    public var animationDuration: Double {
        get { self[AnimationDuration.self] }
        set { self[AnimationDuration.self] = newValue }
    }
}

extension View {

    public func animationDuration(_ value: Double) -> some View {
        environment(\.animationDuration, value)
    }
}

extension Curve {
    
    public static var `default` = Curve.easeInOut
}

extension EnvironmentValues {
    
    private enum CurveKey: EnvironmentKey {
        
        static var defaultValue: Curve { .default }
    }
    
    public var curve: Curve {
        get { self[CurveKey.self] }
        set { self[CurveKey.self] = newValue }
    }
}

extension View {

    public func curve(_ value: Curve) -> some View {
        environment(\.curve, value)
    }
}
