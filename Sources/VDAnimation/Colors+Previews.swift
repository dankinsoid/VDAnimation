import SwiftUI

#Preview {
    let colorSpaces: [(String, (XYZ, XYZ, Double) -> XYZ)] = [
        ("OKLab",
         { l, r, t in OKLab.lerp(OKLab(xyz: l), OKLab(xyz: r), t).xyz }),
        ("OKLCH",
         { l, r, t in OKLCH.lerp(OKLCH(xyz: l), OKLCH(xyz: r), t).xyz }),
        ("OKLCH mix",
         { l, r, t in OKLCH.mix(OKLCH(xyz: l), OKLCH(xyz: r), t).xyz }),
    ]
    let gradients: [(String, DisplayP3, DisplayP3)] = [
        ("Blue→White-Yellow", DisplayP3(r: 0.0, g: 0.2, b: 1.0), DisplayP3(r: 1.0, g: 0.97, b: 0.75)),
        ("Red→Green",         DisplayP3(r: 1.0, g: 0.0, b: 0.0), DisplayP3(r: 0.0, g: 0.8, b: 0.2)),
        ("Red→Blue",          DisplayP3(r: 1.0, g: 0.0, b: 0.0), DisplayP3(r: 0.0, g: 0.2, b: 1.0)),
        ("Red→White",         DisplayP3(r: 1.0, g: 0.0, b: 0.0), DisplayP3(r: 1.0, g: 1.0, b: 1.0)),
        ("Green→Gray",        DisplayP3(r: 0.0, g: 0.8, b: 0.2), DisplayP3(r: 0.5, g: 0.5, b: 0.5)),
        ("Black→Orange",      DisplayP3(r: 0.0, g: 0.0, b: 0.0), DisplayP3(r: 1.0, g: 0.5, b: 0.0)),
        ("White→Black",       DisplayP3(r: 1.0, g: 1.0, b: 1.0), DisplayP3(r: 0.0, g: 0.0, b: 0.0)),
        ("DarkBlue→Cyan",     DisplayP3(r: 0.0, g: 0.0, b: 0.5), DisplayP3(r: 0.4, g: 0.9, b: 1.0)),
        ("Pink→Gold",         DisplayP3(r: 0.9, g: 0.3, b: 0.5), DisplayP3(r: 0.85, g: 0.7, b: 0.2)),
        ("Teal→Coral",        DisplayP3(r: 0.1, g: 0.7, b: 0.7), DisplayP3(r: 0.95, g: 0.4, b: 0.3)),
    ]
    ScrollView {
        VStack(spacing: 16) {
            ForEach(Array(gradients.enumerated()), id: \.offset) { _, gradient in
                let (label, from, to) = gradient
                let fromXYZ = from.xyz
                let toXYZ = to.xyz
                VStack(alignment: .leading, spacing: 0) {
                    let fromLCH = OKLCH(xyz: fromXYZ)
                    let toLCH = OKLCH(xyz: toXYZ)
                    
                    Text(label)
                       
                    ForEach(Array(colorSpaces.enumerated()), id: \.offset) { _, space in
                        let (name, lerp) = space
                        HStack(spacing: 4) {
                            Text(name)
                                .frame(width: 70, alignment: .leading)
                            HStack(spacing: 0) {
                                ForEach(0..<180, id: \.self) { i in
                                    let t = Double(i) / 179
                                    Color(
                                        rgba: WithOpacity(DisplayP3(xyz: lerp(fromXYZ, toXYZ, t)))
                                    )
                                }
                            }
                        }
                        .frame(height: 30)
                    }
                    HStack(spacing: 4) {
                        Text("SwiftUI")
                            .frame(width: 70, alignment: .leading)
                        LinearGradient(
                            colors: [
                                Color(rgba: WithOpacity(DisplayP3(xyz: fromXYZ))),
                                Color(rgba: WithOpacity(DisplayP3(xyz: toXYZ)))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .frame(height: 30)

//#if canImport(AppKit)
//                    HStack(spacing: 4) {
//                        Text("AppKit")
//                            .frame(width: 70, alignment: .leading)
//                        LinearGradient(
//                            colors: [
//                                Color(rgba: WithOpacity(DisplayP3(xyz: fromXYZ))),
//                                Color(rgba: WithOpacity(DisplayP3(xyz: toXYZ)))
//                            ],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    }
//                    .frame(height: 30)
//#endif

#if canImport(UIKit)
                    HStack(spacing: 4) {
                        Text("UIKit")
                            .frame(width: 70, alignment: .leading)
                        UIKitGradient(from: from, to: to)
                    }
                    .frame(height: 30)
#endif
                }
            }
        }
        .padding()
    }
}

#if canImport(AppKit)

private struct AppKitGradient: NSViewRepresentable {

    let from: DisplayP3
    let to: DisplayP3

    func makeNSView(context: Context) -> AppKitGradientView {
        AppKitGradientView(from: from, to: to)
    }

    func updateNSView(_ nsView: AppKitGradientView, context: Context) {
        nsView.from = from
        nsView.to = to
        nsView.needsDisplay = true
    }
}

private final class AppKitGradientView: NSView {

    var from: DisplayP3
    var to: DisplayP3

    init(from: DisplayP3, to: DisplayP3) {
        self.from = from
        self.to = to
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let gradient = NSGradient(
            starting: NSColor(
                displayP3Red: CGFloat(from.r),
                green: CGFloat(from.g),
                blue: CGFloat(from.b),
                alpha: 1
            ),
            ending: NSColor(
                displayP3Red: CGFloat(to.r),
                green: CGFloat(to.g),
                blue: CGFloat(to.b),
                alpha: 1
            )
        ) else { return }
        gradient.draw(in: bounds, angle: 0)
    }
}
#endif

#if canImport(UIKit)

private struct UIKitGradient: UIViewRepresentable {

    let from: DisplayP3
    let to: DisplayP3

    func makeUIView(context: Context) -> UIKitGradientView {
        UIKitGradientView(from: from, to: to)
    }

    func updateUIView(_ uiView: UIKitGradientView, context: Context) {
        uiView.from = from
        uiView.to = to
        uiView.setNeedsDisplay()
    }
}

private final class UIKitGradientView: UIView {

    var from: DisplayP3
    var to: DisplayP3

    init(from: DisplayP3, to: DisplayP3) {
        self.from = from
        self.to = to
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let p3 = CGColorSpace(name: CGColorSpace.displayP3)
        else { return }
        let colors = [
            CGColor(colorSpace: p3, components: [CGFloat(from.r), CGFloat(from.g), CGFloat(from.b), 1])!,
            CGColor(colorSpace: p3, components: [CGFloat(to.r), CGFloat(to.g), CGFloat(to.b), 1])!,
        ] as CFArray
        guard let gradient = CGGradient(colorsSpace: p3, colors: colors, locations: nil) else { return }
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: bounds.minX, y: bounds.midY),
            end: CGPoint(x: bounds.maxX, y: bounds.midY),
            options: []
        )
    }
}
#endif
