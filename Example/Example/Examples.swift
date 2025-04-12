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
                    .duration(.relative((1 - arcSize) / (1 + arcSize))) // compute duration to keep movement speed constant
    
                Parallel()
                    .start(1.0 - 0.01) // animate .start property of the state
                    .curve(.cubicEaseOut)
            }
            .duration(1)
            .sync() // synchronize all loaders across the app
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
                ForEach(Array(values.enumerated()), id: \.offset) { value in
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(y: value.element)
                }
            }
        } motion: {
            Parallel { index in
                To(-10)
                    .duration(0.3)
                    .curve(.easeInOut)
                    .autoreverse()
                    .delay(.relative(Double(index) / Double(values.count * 2 - 1)))
            }
            .sync() // synchronize all loaders across the app
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .onAppear {
            $values.play(repeat: true)
        }
    }
}

struct PathAnimation: View {

    @MotionState var path: Path = Self.heartPath

    var body: some View {
        VStack {
            WithMotion(_path) { path in
                path.fill()
            } motion: {
                Sequential {
                    Wait()
                    To(Self.starPath)
                    Wait()
                }
                .duration(1)
                .autoreverse()
            }
            .frame(width: 100, height: 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
        }
        .onAppear {
            $path.play(repeat: true)
        }
    }

    private static let starPath = makeStarPath(center: CGPoint(x: 50, y: 50), radius: 50, points: 5)
    private static let heartPath = makeHeartPath(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    private static func makeStarPath(center: CGPoint, radius: CGFloat, points: Int) -> Path {
        let path = CGMutablePath()
        let angle = CGFloat.pi * 2 / CGFloat(points * 2)

        for i in 0 ..< points * 2 {
            let r = i.isMultiple(of: 2) ? radius : radius * 0.4
            let x = center.x + r * cos(angle * CGFloat(i) - .pi / 2)
            let y = center.y + r * sin(angle * CGFloat(i) - .pi / 2)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return Path(path)
    }

    private static func makeHeartPath(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        
        // Calculate Radius of Arcs using Pythagoras
        let sideOne = rect.width * 0.4
        let sideTwo = rect.height * 0.3
        let arcRadius = sqrt(sideOne * sideOne + sideTwo * sideTwo) / 2
        
        // Left Hand Curve
        path.addArc(withCenter: CGPoint(x: rect.width * 0.3, y: rect.height * 0.35), radius: arcRadius, startAngle: 135.degreesToRadians, endAngle: 315.degreesToRadians, clockwise: true)
        
        // Top Centre Dip
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height * 0.2))
        
        // Right Hand Curve
        path.addArc(withCenter: CGPoint(x: rect.width * 0.7, y: rect.height * 0.35), radius: arcRadius, startAngle: 225.degreesToRadians, endAngle: 45.degreesToRadians, clockwise: true)
        
        // Right Bottom Line
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.95))
        
        // Left Bottom Line
        path.close()
        
        return Path(path.cgPath)
    }
}

extension Int {
    var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}

struct InteractiveAnimation: View {

    @MotionState private var animation = Props()
    
    @Tweenable
    struct Props {
        var color: Color = .red
        var angle: Angle = .zero
        var offset: CGFloat = -120
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WithMotion(_animation) { props in
                VStack(spacing: 10) {
                    Rectangle()
                        .fill(props.color)
                        .rotationEffect(props.angle, anchor: .center)
                        .offset(x: props.offset)
                        .frame(width: 100, height: 100)
                    Slider(value: _animation.$progress, in: 0...1)
                        .padding(.horizontal)
                }
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

struct ComplexMovement: View {

    @MotionState var location = CGPoint(x: -100, y: 0)

    var body: some View {
        Circle()
            .fill(Color.white)
            .withMotion(_location) {
                $0.position($1)
            } motion: {
                Lerp { t in
                    CGPoint(
                        x: cos(Double.lerp(0, .pi * 2, t)) * 100,
                        y: sin(Double.lerp(0, .pi * 6, t)) * 40
                    )
                }
                .duration(2)
            }
            .offset(y: 10)
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .onAppear {
                $location.play(repeat: true)
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
        
        backgroundColor = .clear
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
                .delayAfter(.relative(0.4))
                .duration(2)
        }
        .play(repeat: true)
    }
}

enum Previews: PreviewProvider {

    static var previews: some View {
        LoaderAnimation()
            .previewDisplayName("Circle loader")
        DotsAnimation()
            .previewDisplayName("Dots loader")
        PathAnimation()
            .previewDisplayName("Path morphing")
        InteractiveAnimation()
            .previewDisplayName("Interactive")
        ComplexMovement()
            .previewDisplayName("Complex movement")
        UIKitExample()
            .previewDisplayName("UIKit")
    }
}
