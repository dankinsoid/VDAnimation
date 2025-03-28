import SwiftUI

public extension View {

    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder _ content: @escaping (AnyView) -> (Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp) { content($0)($1) }
    }

    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp, content)
    }

    @_disfavoredOverload
    func animated<Value: Equatable & Codable, Content: View>(
        _ value: Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp, content)
    }

    func animated<Value: Equatable, Content: View>(
        _ value: Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        lerp: @escaping (Value, Value, Double) -> Value,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        modifier(
            AnimatedTweenModifier(value, lerp: lerp, duration: duration, curve: curve, content: content)
        )
    }

    func animated<Value, Content: View>(
        _ controller: AnimationController,
        lerp: @escaping (Double) -> Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        modifier(
            AnimatedModifier(
                controller: controller,
                duration: { duration },
                lerp: { lerp(curve($0)) },
                result: content
            )
        )
    }

    func animated<Value, Content: View>(
        _ controller: AnimationController,
        tween: Tween<Value>,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(
            controller,
            lerp: tween.lerp,
            duration: duration,
            curve: curve,
            content: content
        )
    }
}

public struct Animated<Value, Modifier: ViewModifier>: View {

    let modifier: Modifier
    
    public var body: some View {
        EmptyView()
            .modifier(modifier)
    }
}

extension Animated  {
    
    public init<Result: View>(
        _ controller: AnimationController,
        tween: Tween<Value>,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Value: Tweenable, Modifier == AnimatedModifier<Value, Result> {
        modifier = AnimatedModifier(
            controller: controller,
            duration: { duration },
            lerp: tween.lerp
        ) { _, value in content(value) }
    }

    public init<Result: View>(
        _ controller: AnimationController,
        lerp: @escaping (Double) -> Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Modifier == AnimatedModifier<Value, Result>  {
        modifier = AnimatedModifier(
            controller: controller,
            duration: { duration },
            lerp: lerp
        ) { _, value in content(value) }
    }
}

extension Animated  {
    
    public init<Result: View>(
        _ value: Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Value: Equatable, Value: Tweenable, Modifier == AnimatedTweenModifier<Value, Result> {
        modifier = AnimatedTweenModifier(
            value,
            lerp: Value.lerp,
            duration: duration,
            curve: curve
        ) { _, value in content(value) }
    }

    public init<Result: View>(
        _ value: Value,
        lerp: @escaping (Value, Value, Double) -> Value,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Value: Equatable, Modifier == AnimatedTweenModifier<Value, Result> {
        modifier = AnimatedTweenModifier(
            value,
            lerp: lerp,
            duration: duration,
            curve: curve
        ) { _, value in content(value) }
    }
}


public final class AnimationController: ObservableObject {
    
    @Published
    fileprivate(set) public var targetProgress = 0.0
    @Published
    fileprivate var state = AnimationControllerState() {
        didSet {
            updateState()
        }
    }
    fileprivate var repeatForever = false
    fileprivate(set) public var currentProgress = 0.0
    fileprivate(set) public var isAnimating = false
    var duration: () -> TimeInterval = { 0.25 }
    var onBreak: (Double) -> Void = { _ in }
    
    public init() {}

    public func play(
        from: Double? = nil,
        to progress: Double? = nil,
        repeat repeatForever: Bool = false
    ) {
        self.repeatForever = repeatForever
        state = AnimationControllerState(
            tween: Tween(from ?? currentProgress, progress ?? state.tween.end),
            needAnimate: true
        )
    }

    public func reverse(from: Double? = nil) {
        state = AnimationControllerState(
            tween: Tween(
                from ?? currentProgress,
                state.tween.end > state.tween.start && currentProgress != 0.0
                || currentProgress == 1.0 ? 0.0 : 1.0
            ),
            needAnimate: true
        )
    }

    public func toggle() {
        state = AnimationControllerState(
            tween: Tween(currentProgress, state.tween.end),
            needAnimate: !isAnimating
        )
    }

    public func set(progress: Double) {
        state = AnimationControllerState(
            tween: Tween(progress, progress),
            needAnimate: false
        )
    }

    public func pause() {
        stop(at: currentProgress)
    }

    public func stop(at progress: Double = 0) {
        state = AnimationControllerState(
            tween: Tween(progress, state.tween.end),
            needAnimate: false
        )
    }

    private func updateState() {
        if isAnimating {
            isAnimating = false
            withAnimation(.easeOut(duration: 0.0)) {
                targetProgress = state.tween.start
            }
        } else {
            targetProgress = state.tween.start
        }
        guard state.needAnimate else {
            onBreak(currentProgress)
            return
        }
        var animation: Animation = .linear(
            duration: duration() * abs(state.tween.end - state.tween.start)
        )
        if repeatForever {
            animation = animation.repeatForever(autoreverses: false)
        }
        isAnimating = true
        withAnimation(animation) {
            targetProgress = state.tween.end
        }
    }
}

private struct AnimationControllerState: Equatable {

    var tween = Tween(0.0, 1.0)
    var needAnimate = false
}

public struct AnimatedTweenModifier<Value: Equatable, Result: View>: ViewModifier {

    @State private var props: Props
    let value: Value
    let lerp: (Value, Value, Double) -> Value
    let duration: TimeInterval
    let curve: Curve
    let content: (AnyView, Value) -> Result

    @State
    private var controller = AnimationController()

    init(
        _ value: Value,
        lerp: @escaping (Value, Value, Double) -> Value,
        duration: TimeInterval,
        curve: Curve,
        @ViewBuilder content: @escaping (AnyView, Value) -> Result
    ) {
        self.value = value
        self.lerp = lerp
        self.content = content
        self.duration = duration
        self.curve = curve
        _props = State(wrappedValue: Props(value, value))
    }

    public func body(content: Content) -> some View {
        content
            .modifier(
                AnimatedModifier(
                    controller: controller,
                    duration: { duration },
                    lerp: { lerp(props.start, props.end, curve($0)) },
                    result: self.content,
                    observer: { isAnimating, progress, value in }
                )
            )
            .onChange(of: value) { newValue in
                if controller.isAnimating {
                    controller.pause()
                }
                props.start = lerp(props.start, props.end, controller.currentProgress)
                props.end = newValue
                if props.start != props.end {
                    controller.play(from: 0)
                } else {
                    controller.stop()
                }
            }
    }

    final class Props {

        var start: Value
        var end: Value

        init(_ start: Value, _ end: Value) {
            self.start = start
            self.end = end
        }
    }
}

public struct AnimatedModifier<Value, Result: View>: ViewModifier {

    @ObservedObject
    var controller: AnimationController
    let duration: () -> Double
    let lerp: (Double) -> Value
    let result: (AnyView, Value) -> Result
    var observer: (Bool, Double, Value) -> Void = { _, _, _ in }

    public func body(content: Content) -> some View {
        controller.duration = duration
        controller.onBreak = { observer(false, $0, lerp($0)) }
        return content
            .modifier(
                AnimationModifier(
                    animatableData: controller.targetProgress,
                    lerp: lerp,
                    result: result
                ) { progress, value in
                    let isAnimating = controller.isAnimating
                    controller.currentProgress = progress
                    if isAnimating, progress == controller.state.tween.end {
                        controller.isAnimating = false
                    }
                    if isAnimating {
                        observer(isAnimating, progress, value)
                        if !controller.isAnimating {
                            observer(false, progress, value)
                        }
                    }
                }
            )
    }
}

struct AnimationModifier<Value, Body: View>: AnimatableModifier {

    var animatableData: Double
    let lerp: (Double) -> Value
    let result: (AnyView, Value) -> Body
    let observer: (Double, Value) -> Void

    func body(content: Content) -> Body {
        let currentValue = lerp(animatableData)
        observer(animatableData, currentValue)
        return result(AnyView(content), currentValue)
    }
}
