import SwiftUI

extension View {

    public func withMotion<Value, Content: View>(
        _ state: MotionState<Value>,
        repeat repeatForever: Bool = false,
        @ViewBuilder content: @escaping (AnyView, Value) -> Content,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> some View {
        WithMotionModifier(
            state: state,
            child: self,
            motion: motion(),
            content: content,
            repeatForever: repeatForever
        )
    }
}

public struct WithMotion<Value, Content: View>: View {

    let state: MotionState<Value>
    let content: (Value) -> Content
    let repeatForever: Bool
    let motion: () -> AnyMotion<Value>

    public init(
        _ state: MotionState<Value>,
        repeat repeatForever: Bool = false,
        @ViewBuilder content: @escaping (Value) -> Content,
        @MotionBuilder<Value> motion: @escaping () -> AnyMotion<Value>
    ) {
        self.state = state
        self.content = content
        self.motion = motion
        self.repeatForever = repeatForever
    }

    public var body: some View {
        EmptyView()
            .withMotion(state, repeat: repeatForever) { _, value in
                content(value)
            } motion: {
                motion()
            }
    }
}

@propertyWrapper
public struct MotionState<Value>: DynamicProperty {

    @State
    public var wrappedValue: Value

    @State
    fileprivate var controller = AnimationController()

    public var projectedValue: AnimationController {
        controller
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension MotionState where Value == Double {

    public init() {
        self.init(wrappedValue: 0.0)
    }
}

struct WithMotionModifier<Value,  Child: View, Content: View>: View {

    let state: MotionState<Value>
    let child: Child
    let motion: AnyMotion<Value>
    let content: (AnyView, Value) -> Content
    let repeatForever: Bool
    @State private var wrapper = Wrapper()

    var body: some View {
        child
            .modifier(
                AnimatedModifier(
                    controller: state.controller,
                    duration: {
                        let info = motion.prepare(state.wrappedValue, nil)
                        let duration = info.duration?.seconds ?? 0.25
                        wrapper.info = info
                        return duration
                    },
                    lerp: { t in wrapper.info?.lerp(state.wrappedValue, t) ?? state.wrappedValue },
                    result: content
                ) { isAnimating, progress, value in
                    if isAnimating {
                        let last = wrapper.lastProgress
                        if last != progress {
                            wrapper.lastProgress = progress
                            if let effects = wrapper.info?.sideEffects {
                                DispatchQueue.main.async {
                                    let last = last ?? progress
                                    let range = min(last, progress)...max(last, progress)
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

    private final class Wrapper {

        var info: MotionData<Value>?
        var lastProgress: Double?
    }
}
