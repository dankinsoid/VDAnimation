import SwiftUI

public extension View {
    /// Applies motion animation to a view with a given state.
    ///
    /// - Parameters:
    ///   - state: The motion state to animate.
    ///   - content: A closure that takes the view and current value to create the animated content.
    ///   - motion: A closure that returns the motion to apply.
    /// - Returns: A view with the motion animation applied.
    func withMotion<Value, Content: View>(
        _ state: MotionState<Value>,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> some View {
        modifier(
            WithMotionModifier(
                state: state,
                motion: motion(),
                content: content
            )
        )
    }
}

/// A view that applies motion animation to its content.
public struct WithMotion<Value, Content: View>: View {
    let state: MotionState<Value>
    let content: (Value) -> Content
    let motion: () -> AnyMotion<Value>

    /// Creates a new motion animated view.
    ///
    /// - Parameters:
    ///   - state: The motion state to animate.
    ///   - content: A closure that takes the current value to create the animated content.
    ///   - motion: A closure that returns the motion to apply.
    public init(
        _ state: MotionState<Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @MotionBuilder<Value> motion: @escaping () -> AnyMotion<Value>
    ) {
        self.state = state
        self.content = content
        self.motion = motion
    }

    public var body: some View {
        VStack {
            EmptyView()
                .modifier(
                    WithMotionModifier(
                        state: state,
                        motion: motion(),
                        content: { _, value in content(value) }
                    )
                )
        }
    }
}

/// A property wrapper that holds a value and its animation controller.
///
/// Use this to create state that can be animated with motion animations.
@propertyWrapper
public struct MotionState<Value>: DynamicProperty {
    /// The underlying value that will be animated.
    @State
    public var wrappedValue: Value

    @State
    fileprivate var controller = AnimationController()

    /// The animation controller associated with this state.
    public var projectedValue: AnimationController {
        controller
    }

    @Binding
    public var progress: Double

    @Binding
    public var isAnimating: Bool

    /// Creates a new motion state with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value of the state.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        _progress = .constant(0)
        _isAnimating = .constant(false)
        _progress = Binding { [controller] in
            controller.progress
        } set: { [controller] newValue in
            controller.progress = newValue
        }
        _isAnimating = Binding { [controller] in
            controller.isAnimating
        } set: { [controller] newValue in
            controller.isAnimating = newValue
        }
    }
}

public extension MotionState where Value == Double {
    /// Creates a new motion state with an initial value of 0.0.
    init() {
        self.init(wrappedValue: 0.0)
    }
}

/// A view modifier that implements the motion animation.
///
/// This is an internal implementation struct used by the `withMotion` view modifier.
struct WithMotionModifier<Value, Result: View>: ViewModifier {
    let state: MotionState<Value>
    let motion: AnyMotion<Value>
    let content: (AnyView, Value) -> Result
    @State private var wrapper = Wrapper()
    @Environment(\.animationDuration)
    private var defaultDuration

    func body(content: Content) -> some View {
        let value = state.wrappedValue
        return content.modifier(
            AnimatedModifier(
                controller: state.controller,
                duration: { [motion, wrapper, defaultDuration] in
                    let info = motion.prepare(value, nil)
                    let duration = info.duration?.seconds ?? defaultDuration
                    wrapper.info = info
                    return duration
                },
                lerp: { [wrapper] t in wrapper.info?.lerp(state.wrappedValue, t) ?? value },
                curve: .linear,
                result: self.content
            ) { [wrapper] isAnimating, progress, value in
                if isAnimating {
                    let last = wrapper.lastProgress
                    if last != progress {
                        wrapper.lastProgress = progress
                        if let effects = wrapper.info?.sideEffects {
                            DispatchQueue.main.async {
                                let last = last ?? progress
                                let range = min(last, progress) ... max(last, progress)
                                let active = effects(range)
                                for effect in active {
                                    effect(value)
                                }
                            }
                        }
                    }
                } else {
                    wrapper.lastProgress = nil
                }
            }
        )
    }

    /// A wrapper class to store animation data between view updates.
    private final class Wrapper {
        var info: MotionData<Value>?
        var lastProgress: Double?
    }
}
