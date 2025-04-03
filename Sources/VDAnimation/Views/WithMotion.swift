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
        _VariadicView.Tree(Wrapper(base: self)) {}
    }

    private struct Wrapper: _VariadicView.UnaryViewRoot {

        let base: WithMotion

        func body(children: _VariadicView.Children) -> some View {
            Group{}.modifier(
                WithMotionModifier(
                    state: base.state,
                    motion: base.motion(),
                    content: { _, value in base.content(value) }
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
    fileprivate var controller: AnimationController
    @ObservedObject
    fileprivate var animating: Animating

    /// The animation controller associated with this state.
    public var projectedValue: AnimationController {
        controller
    }

    @BindingRef
    public var progress: Double

    @BindingRef
    public var isAnimating: Bool

    /// Creates a new motion state with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value of the state.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        let controller = AnimationController()
        _controller = State(wrappedValue: controller)
        _progress = BindingRef {
            controller.progress
        } setter: { newValue in
            controller.progress = newValue
        }
        _isAnimating = BindingRef {
            controller.isAnimating
        } setter: { newValue in
            controller.isAnimating = newValue
        }
        _animating = ObservedObject(wrappedValue: controller.animating)
    }
}

// This type is needed bacause Binding caches values that leads to unpredictable behaviuor so Binding itself should be a computed property
@propertyWrapper
public struct BindingRef<Value> {
    
    let getter: () -> Value
    let setter: (Value) -> Void
    
    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        Binding {
            wrappedValue
        } set: {
            wrappedValue = $0
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
        content.modifier(
            AnimatedModifier(
                controller: state.controller,
                duration: { [motion, wrapper, defaultDuration] in
                    let info = info()
                    let duration = info.duration?.seconds ?? defaultDuration
                    return duration
                },
                lerp: { [wrapper] t in info().lerp(state.wrappedValue, t) },
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

    private func info() -> MotionData<Value> {
        if let info = wrapper.info {
            return info
        }
        let info = motion.prepare(state.wrappedValue, nil)
        wrapper.info = info
        return info
    }
    
    /// A wrapper class to store animation data between view updates.
    private final class Wrapper {
        var info: MotionData<Value>?
        var lastProgress: Double?
    }
}
