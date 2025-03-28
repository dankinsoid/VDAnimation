import SwiftUI

public extension View {

    func animated<Value: Equatable, Content: View>(
        _ value: Value,
        animation: Animation = .default,
        lerp: @escaping (Value, Value, Double) -> Value,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        AnimatedTweenView(value, animation, lerp: lerp, child: { self }, content: content)
    }

    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        animation: Animation = .default,
        @ViewBuilder _ content: @escaping (AnyView) -> (Value) -> Content
    ) -> some View {
        animated(value, animation: animation, lerp: Value.lerp) { content($0)($1) }
    }

    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        animation: Animation = .default,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, animation: animation, lerp: Value.lerp, content)
    }

    @_disfavoredOverload
    func animated<Value: Equatable & Codable, Content: View>(
        _ value: Value,
        animation: Animation = .default,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, animation: animation, lerp: Value.lerp, content)
    }

    func animated<Value, Content: View>(
        _ controller: AnimationController,
        duration: TimeInterval = 0.25,
        curve: Curve = .easeInOut,
        lerp: @escaping (Double) -> Value,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        modifier(
            AnimatedView(
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
            duration: duration,
            curve: curve,
            lerp: tween.lerp,
            content: content
        )
    }
}

public final class AnimationController: ObservableObject {

    @Published
    fileprivate(set) public var targetProgress = 0.0
    @Published
    fileprivate var state = AnimationControllerState()
    fileprivate var repeatForever = false
    fileprivate(set) public var currentProgress = 0.0
    fileprivate(set) public var isAnimating = false

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
}

private struct AnimationControllerState: Equatable {
    var tween = Tween(0.0, 1.0)
    var needAnimate = false
}

private struct AnimatedTweenView<Value: Equatable, Child: View, Content: View>: View {

    @State private var props: Props
    let value: Value
    let lerp: (Value, Value, Double) -> Value
    let animation: Animation?
    let child: Child
    let content: (AnyView, Value) -> Content

    init(
        _ value: Value,
        _ animation: Animation? = .default,
        lerp: @escaping (Value, Value, Double) -> Value,
        @ViewBuilder child: () -> Child,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content
    ) {
        self.value = value
        self.lerp = lerp
        self.child = child()
        self.content = content
        self.animation = animation
        _props = State(wrappedValue: Props(progress: 0.0, start: value, end: value))
    }

    var body: some View {
        child
            .modifier(
                AnimatedTweenModifier(
                    animatableData: props.progress,
                    value: value,
                    lerp: { lerp(props.start, props.end, $0) },
                    result: content
                ) { isAnimating, start, end in
                    withAnimation(.easeInOut(duration: 0)) {
                        props = Props(progress: 0.0, start: start, end: end)
                    }
                    withAnimation(animation) {
                        props = Props(progress: 1.0, start: start, end: end)
                    }
                } observer: { _, _ in }
            )
    }

    struct Props {

        var progress: Double
        var start: Value
        var end: Value
    }
}

private struct AnimatedTweenModifier<Value: Equatable, Result: View>: AnimatableModifier {

    var animatableData: Double
    let value: Value
    let lerp: (Double) -> Value
    let result: (AnyView, Value) -> Result
    let onStartAnimation: (Bool, Value, Value) -> Void
    let observer: (Double, Value) -> Void

    func body(content: Content) -> some View {
        let currentValue = lerp(animatableData)
        observer(animatableData, currentValue)
        return result(AnyView(content), currentValue)
            .onChange(of: value) { newValue in
                onStartAnimation(animatableData != 0.0 && animatableData != 1.0, currentValue, newValue)
            }
    }
}

struct AnimatedView<Value, Result: View>: ViewModifier {

    @ObservedObject
    var controller: AnimationController
    let duration: () -> Double
    let lerp: (Double) -> Value
    let result: (AnyView, Value) -> Result
    var observer: (Bool, Double, Value) -> Void = { _, _, _ in }

    func body(content: Content) -> some View {
        content
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
            .onChange(of: controller.state) { newValue in
                if controller.isAnimating {
                    controller.isAnimating = false
                    withAnimation(.easeOut(duration: 0.0)) {
                        controller.targetProgress = newValue.tween.start
                    }
                } else {
                    controller.targetProgress = newValue.tween.start
                }
                guard newValue.needAnimate,
                        controller.currentProgress != newValue.tween.end
                        || controller.repeatForever
                else {
                    observer(false, controller.currentProgress, lerp(controller.currentProgress))
                    return
                }
                var animation: Animation = .linear(
                    duration: duration() * abs(newValue.tween.end - newValue.tween.start)
                )
                if controller.repeatForever {
                    animation = animation.repeatForever(autoreverses: false)
                }
                controller.isAnimating = true
                withAnimation(animation) {
                    controller.targetProgress = newValue.tween.end
                }
            }
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

#Preview {
//    ContentView()
}
