import SwiftUI
import VDAnimation

struct LoaderAnimation: View {

    @MotionState private var state = Tween(0.0, 0.01)
    private let arcSize = 0.4

    var body: some View {
        WithMotion(_state) { value in
            Circle()
                .trim(from: value.start, to: value.end)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(-.degrees(90), anchor: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green)
        } motion: {
            Sequential {
                Parallel()
                    .end(arcSize) // animate .end property of the state
                    .curve(.cubicEaseIn)
    
                To(Tween(1 - arcSize, 1.0)) // animate the whole state
                    .duration(.relative((1 - arcSize) / (1 + arcSize))) // compute duration to
    
                Parallel()
                    .start(1.0 - 0.01) // animate .start property of the state
                    .curve(.cubicEaseOut)
            }
            .duration(1)
        }
        .onAppear {
            $state.play(repeat: true)
        }
    }
}

struct DotsAnimation: View {

    @MotionState private var values: [CGFloat] = [0, 0, 0]

    var body: some View {
        WithMotion(_values) { values in
            HStack(spacing: 12) {
                ForEach(values, id: \.self) { value in
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(y: value)
                }
            }
        } motion: {
            Parallel { index in
                To(-10)
                    .duration(0.3)
                    .curve(.easeInOut)
                    .autoreverse()
                    .delay(.relative(Double(index) * 0.2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .onAppear {
            $values.play(repeat: true)
        }
    }
}

struct InteractiveAnimation: View {

    @MotionState private var animation = Props()
    @State private var color: Color = .blue
    
    @Tweenable
    struct Props {
        var color: Color = .red
        var angle: Angle = .zero
        var offset: CGFloat = -120
    }
    
    var body: some View {
        VStack(spacing: 30) {
            WithMotion(_animation) { props in
                Rectangle()
                    .fill(props.color)
                    .rotationEffect(props.angle, anchor: .center)
                    .offset(x: props.offset)
                    .frame(width: 100, height: 100)
                Slider(value: _animation.$progress, in: 0...1)
                    .padding(.horizontal)
            } motion: {
                To(
                    Props(
                        color: .blue,
                        angle: .degrees(360),
                        offset: 120
                    )
                )
                .duration(2.0)
            }

            HStack {
                if $animation.isAnimating {
                    Button("Pause") { $animation.pause() }
                } else {
                    Button("Play") {
                        if $animation.progress == 1.0 || $animation.progress == 0.0 {
                            $animation.reverse()
                        } else {
                            $animation.play()
                        }
                    }
                }
            }
        }
    }
}

struct UIKitExample: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIKitExampleView {
        UIKitExampleView()
    }

    func updateUIView(_ uiView: UIKitExampleView, context: Context) {
    }
}

final class UIKitExampleView: UIView {

    let label = UILabel()

    @Tweenable
    struct Value {
        var amount: Int = 0
        var color: UIColor = .systemRed
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        
        backgroundColor = .white
        addSubview(label)
        label.font = .monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -100),
             label.centerYAnchor.constraint(equalTo: centerYAnchor)]
        )

        motionDisplayLink(Value()) { [label] value in
            label.text = "\(value.amount) USD"
            label.textColor = value.color
        } motion: {
            To(Value(amount: 1000, color: .systemGreen))
                .delay(.relative(0.2))
                .duration(2)
        }
        .play()
    }
}

enum Previews: PreviewProvider {

    static var previews: some View {
        LoaderAnimation()
            .previewDisplayName("Circle loader")
        DotsAnimation()
            .previewDisplayName("Dots loader")
        InteractiveAnimation()
            .previewDisplayName("Interactive")
        UIKitExample()
            .previewDisplayName("UIKit")
    }
}
