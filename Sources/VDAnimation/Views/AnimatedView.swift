import SwiftUI

/// Extension providing animation capabilities to SwiftUI views
public extension View {

    /// Animates a value change with automatic tweening for types conforming to `Equatable` and `Tweenable`.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder _ content: @escaping (AnyView) -> (Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp) { content($0)($1) }
    }

    /// Animates a value change with automatic tweening for types conforming to `Equatable` and `Tweenable`.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    func animated<Value: Equatable & Tweenable, Content: View>(
        _ value: Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp, content)
    }

    /// Animates a value change for types conforming to `Equatable` and `Codable`.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    @_disfavoredOverload
    func animated<Value: Equatable & Codable, Content: View>(
        _ value: Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        animated(value, duration: duration, curve: curve, lerp: Value.lerp, content)
    }

    /// Animates a value change with a custom linear interpolation function.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - lerp: Custom interpolation function for the value
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    func animated<Value: Equatable, Content: View>(
        _ value: Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        lerp: @escaping (Value, Value, Double) -> Value,
        @ViewBuilder _ content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        modifier(
            AnimatedTweenModifier(value, lerp: lerp, duration: duration, curve: curve, content: content)
        )
    }

    /// Animates a value using an `AnimationController` and custom lerp function.
    /// - Parameters:
    ///   - controller: The animation controller to manage animation state
    ///   - lerp: Function to compute the interpolated value from the progress
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    func animated<Value, Content: View>(
        _ controller: AnimationController,
        lerp: @escaping (Double) -> Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content
    ) -> some View {
        modifier(
            AnimatedModifier(
                controller: controller,
                duration: { duration },
                lerp: lerp,
                curve: curve,
                result: content
            )
        )
    }

    /// Animates a value using an `AnimationController` and a `Tween`.
    /// - Parameters:
    ///   - controller: The animation controller to manage animation state
    ///   - tween: The tween object that defines how values are interpolated
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that takes the view and current animated value
    /// - Returns: A view with animation applied
    func animated<Value: Tweenable, Content: View>(
        _ controller: AnimationController,
        tween: Tween<Value>,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
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

/// A view that renders animated content with various animation configurations
public struct Animated<Modifier: ViewModifier>: View {

    let modifier: Modifier

    /// The content of the `Animated` view
    public var body: some View {
        VStack {
            EmptyView()
                .modifier(modifier)
        }
    }
}

extension Animated  {
    
    /// Creates an animated view using an animation controller and a tween.
    /// - Parameters:
    ///   - controller: The animation controller to manage animation state
    ///   - tween: The tween object that defines how values are interpolated
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that produces content from the animated value
    public init<Value, Result: View>(
        _ controller: AnimationController,
        tween: Tween<Value>,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Value: Tweenable, Modifier == AnimatedModifier<Value, Result> {
        modifier = AnimatedModifier(
            controller: controller,
            duration: { duration },
            lerp: tween.lerp,
            curve: curve
        ) { _, value in content(value) }
    }

    /// Creates an animated view using an animation controller and a custom lerp function.
    /// - Parameters:
    ///   - controller: The animation controller to manage animation state
    ///   - lerp: Function to compute the interpolated value from the progress
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that produces content from the animated value
    public init<Value, Result: View>(
        _ controller: AnimationController,
        lerp: @escaping (Double) -> Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Modifier == AnimatedModifier<Value, Result>  {
        modifier = AnimatedModifier(
            controller: controller,
            duration: { duration },
            lerp: lerp,
            curve: curve
        ) { _, value in content(value) }
    }

    /// Creates an animated view using an animation controlle.
    /// - Parameters:
    ///   - controller: The animation controller to manage animation state
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that produces content from the animated value
    public init<Result: View>(
        _ controller: AnimationController,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder content: @escaping (Double) -> Result
    ) where Modifier == AnimatedModifier<Double, Result> {
        modifier = AnimatedModifier(
            controller: controller,
            duration: { duration },
            lerp: { $0 },
            curve: curve
        ) { _, value in content(value) }
    }
}

extension Animated  {
    
    /// Creates an animated view for a changing value with automatic tweening.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that produces content from the animated value
    public init<Value, Result: View>(
        _ value: Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
        @ViewBuilder content: @escaping (Value) -> Result
    ) where Value: Equatable, Value: Tweenable, Modifier == AnimatedTweenModifier<Value, Result> {
        modifier = AnimatedTweenModifier(
            value,
            lerp: Value.lerp,
            duration: duration,
            curve: curve
        ) { _, value in content(value) }
    }

    /// Creates an animated view for a changing value with a custom lerp function.
    /// - Parameters:
    ///   - value: The value to animate
    ///   - lerp: Custom interpolation function for the value
    ///   - duration: Animation duration in seconds, when nil EnvironmentValue.animationDuration is used, that's equal to 0.25 by default
    ///   - curve: Animation curve to use when nil EnvironmentValue.curve is used, that's equal to .easeInOut by default
    ///   - content: A closure that produces content from the animated value
    public init<Value, Result: View>(
        _ value: Value,
        lerp: @escaping (Value, Value, Double) -> Value,
        duration: TimeInterval? = nil,
        curve: Curve? = nil,
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


/// Controller that manages animation state and exposes methods to control animations
@MainActor
public final class AnimationController: ObservableObject, AnimationDriver {

    /// The target progress value the animation is moving toward
    @Published
    fileprivate(set) public var targetProgress = 0.0
    fileprivate var state = AnimationControllerState() {
        didSet {
            updateState()
        }
    }
    fileprivate var repeatForever = false
    fileprivate var isFirst = true

    /// The current progress of the animation (between 0.0 and 1.0)
    public var progress: Double {
        get { currentProgress }
        set { set(progress: newValue) }
    }

    fileprivate var currentProgress = 0.0
    private var completions: [() -> Void] = []

    /// Indicates whether an animation is currently in progress
    public var isAnimating: Bool {
        get { animating.isAnimating }
        set {
            if newValue {
                play()
            } else {
                pause()
            }
        }
    }

    let animating = Animating()
    var duration: () -> TimeInterval = { .defaultAnimationDuration }
    var onBreak: (Double) -> Void = { _ in }
    
    /// Initializes a new animation controller
    public init() {}

    /// Plays the animation from a specified progress value to another
    /// - Parameters:
    ///   - from: The starting progress value (defaults to current progress if nil)
    ///   - to: The ending progress value (defaults to current state's end value if nil)
    ///   - repeatForever: Whether the animation should repeat indefinitely
    public func play(
        from: Double? = nil,
        to progress: Double? = nil,
        repeat repeatForever: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        if let completion {
            completions.append(completion)
        }
        self.repeatForever = repeatForever
        state = AnimationControllerState(
            tween: Tween(from ?? currentProgress, progress ?? state.tween.end),
            needAnimate: true
        )
    }

    /// Reverses the animation direction
    /// - Parameter from: The starting progress value (defaults to current progress if nil)
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

    /// Toggles the animation state between playing and paused
    public func toggle() {
        state = AnimationControllerState(
            tween: Tween(currentProgress, state.tween.end),
            needAnimate: !isAnimating
        )
    }

    /// Sets the animation directly to a specific progress value without animating
    /// - Parameter progress: The progress value to set (between 0.0 and 1.0)
    private func set(progress: Double) {
        state = AnimationControllerState(
            tween: Tween(progress, state.tween.end),
            needAnimate: false
        )
    }

    /// Pauses the animation at the current progress
    public func pause() {
        state = AnimationControllerState(
            tween: Tween(currentProgress, state.tween.end),
            needAnimate: false
        )
    }

    /// Stops the animation and resets to a specific progress value
    /// - Parameter progress: The progress value to stop at (defaults to 0.0)
    public func stop(at progress: Double = 0) {
        state = AnimationControllerState(
            tween: Tween(progress, state.tween.end),
            needAnimate: false
        )
        notifyCompletions()
    }

    private func updateState() {
        let wasAnimating = isAnimating
        if isAnimating {
            animating.isAnimating = false
            withAnimation(.easeOut(duration: 0.0)) {
                targetProgress = state.tween.start
            }
        } else {
            targetProgress = state.tween.start
        }
        guard state.needAnimate else {
            if wasAnimating {
                onBreak(currentProgress)
            }
            return
        }
        var animation: Animation = .linear(
            duration: duration() * abs(state.tween.end - state.tween.start)
        )
        if repeatForever {
            animation = animation.repeatForever(autoreverses: false)
        }
        animating.isAnimating = true
        isFirst = false
        withAnimation(animation) {
            targetProgress = state.tween.end
        }
    }
    
    fileprivate func notifyCompletions() {
        completions.forEach { $0() }
        completions = []
    }
}

final class Animating: ObservableObject {

    @Published var isAnimating = false
}

private struct AnimationControllerState: Equatable {

    var tween = Tween(0.0, 1.0)
    var needAnimate = false
}

/// A view modifier that animates between values using tweening
public struct AnimatedTweenModifier<Value: Equatable, Result: View>: ViewModifier {

    @State private var props: Props
    let value: Value
    let lerp: (Value, Value, Double) -> Value
    let duration: TimeInterval?
    let curve: Curve?
    let content: (AnyView, Value) -> Result

    @State
    private var controller = AnimationController()

    init(
        _ value: Value,
        lerp: @escaping (Value, Value, Double) -> Value,
        duration: TimeInterval?,
        curve: Curve?,
        @ViewBuilder content: @escaping (AnyView, Value) -> Result
    ) {
        self.value = value
        self.lerp = lerp
        self.content = content
        self.duration = duration
        self.curve = curve
        _props = State(wrappedValue: Props(value, value))
    }

    /// Modifies the view content by applying animation
    public func body(content: Content) -> some View {
        return content
            .modifier(
                AnimatedModifier(
                    controller: controller,
                    duration: { duration },
                    lerp: { lerp(props.start, props.end, $0) },
                    curve: curve,
                    result: self.content,
                    observer: { _isAnimating, progress, value in }
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

/// A view modifier that animates using an animation controller
public struct AnimatedModifier<Value, Result: View>: ViewModifier {

    @ObservedObject
    var controller: AnimationController
    @Environment(\.animationDuration)
    private var defaultDuration
    let duration: () -> Double?
    let lerp: (Double) -> Value
    let curve: Curve?
    let result: (AnyView, Value) -> Result
    var observer: (Bool, Double, Value) -> Void = { _, _, _ in }
    @Environment(\.curve)
    private var defaultCurve

    /// Modifies the view content by applying animation
    public func body(content: Content) -> some View {
        let defaultDuration = self.defaultDuration
        let curve = self.curve ?? defaultCurve
        controller.duration = { duration() ?? defaultDuration }
        controller.onBreak = { observer(false, $0, lerp($0)) }
        return content
            .modifier(
                AnimationModifier(
                    animatableData: controller.targetProgress,
                    lerp: { lerp(curve($0)) },
                    result: result
                ) { progress, value in
                    let wasAnimating = controller.isAnimating
                    controller.currentProgress = progress
                    guard wasAnimating else { return }
                    observer(true, progress, value)
                    if progress == controller.state.tween.end, !controller.repeatForever {
                        controller.animating.isAnimating = false
                        observer(false, progress, value)
                        DispatchQueue.main.async {
                            controller.notifyCompletions()
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
