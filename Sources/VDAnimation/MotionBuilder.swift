import Foundation

@resultBuilder
public enum MotionBuilder<Value> {

    public static func buildBlock(_ component: AnyMotion<Value>) -> AnyMotion<Value> {
        component
    }

    public static func buildExpression(_ expression: some Motion<Value>) -> AnyMotion<Value> {
        expression.anyMotion
    }

    public static func buildExpression(_ expression: Value) -> AnyMotion<Value> where Value: Tweenable {
        To(expression).anyMotion
    }

    public static func buildEither(first component: AnyMotion<Value>) -> AnyMotion<Value> {
        component
    }
    
    public static func buildEither(second component: AnyMotion<Value>) -> AnyMotion<Value> {
        component
    }
    
    public static func buildLimitedAvailability(_ component: AnyMotion<Value>) -> AnyMotion<Value> {
        component
    }
}

@resultBuilder
public enum MotionsArrayBuilder<Value> {
    
    public static func buildPartialBlock(first components: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        components
    }

    public static func buildPartialBlock(accumulated: [AnyMotion<Value>], next: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        accumulated + next
    }
    
    public static func buildExpression(_ expression: some Motion<Value>) -> [AnyMotion<Value>] {
        [expression.anyMotion]
    }
    
    public static func buildExpression(_ expression: Value) -> [AnyMotion<Value>] where Value: Tweenable {
        [To(expression).anyMotion]
    }
    
    public static func buildExpression<C: Sequence>(_ expression: C) -> [AnyMotion<Value>] where C.Element: Motion<Value> {
        expression.map(\.anyMotion)
    }
    
    public static func buildExpression<C: Sequence>(_ expression: C) -> [AnyMotion<Value>] where C.Element == AnyMotion<Value> {
        expression.map(\.anyMotion)
    }

    public static func buildArray(_ components: [[AnyMotion<Value>]]) -> [AnyMotion<Value>] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [AnyMotion<Value>]?) -> [AnyMotion<Value>] {
        component ?? []
    }
    
    public static func buildEither(first component: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        component
    }
    
    public static func buildEither(second component: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        component
    }

    public static func buildLimitedAvailability(_ component: [AnyMotion<Value>]) -> [AnyMotion<Value>] {
        component
    }
}
