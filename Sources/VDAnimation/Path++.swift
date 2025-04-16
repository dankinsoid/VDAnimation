import SwiftUI

@resultBuilder
public enum ShapesArrayBuilder {
    public static func buildArray(_ components: [[any Shape]]) -> [any Shape] {
        Array(components.joined())
    }

    public static func buildBlock() -> [any Shape] {
        []
    }

    public static func buildBlock(_ components: [any Shape]...) -> [any Shape] {
        buildArray(components)
    }

    public static func buildOptional(_ component: [any Shape]?) -> [any Shape] {
        component ?? []
    }

    public static func buildExpression(_ expression: some Shape) -> [any Shape] {
        [expression]
    }

    public static func buildExpression<C: Sequence>(_ expression: C) -> [any Shape] where C.Element: Shape {
        expression.map { $0 }
    }

    public static func buildExpression<C: Sequence>(_ expression: C) -> [any Shape] where C.Element == any Shape {
        expression.map { $0 }
    }
}

public struct OptionalShape<Wrapped: Shape>: Shape {
    public var wrapped: Wrapped?

    public func path(in rect: CGRect) -> Path {
        wrapped?.path(in: rect) ?? Path()
    }
}

public struct UnionShape: Shape {
    public var children: [any Shape]

    public func path(in rect: CGRect) -> Path {
        var result = Path()
        for child in children {
            result.addPath(child.path(in: rect))
        }
        return result
    }
}

public struct Line: Shape {
    public var angle: Angle
    public var alignment: Alignment

    public init(
        angle: Angle = .zero,
        alignment: Alignment = .center
    ) {
        self.angle = angle
        self.alignment = alignment
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let length = min(rect.width, rect.height)
        let dx = cos(angle.radians) * length / 2
        let dy = sin(angle.radians) * length / 2

        let start = CGPoint(x: center.x - dx, y: center.y - dy)
        let end = CGPoint(x: center.x + dx, y: center.y + dy)

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
    }

//    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
//    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
//
//    }
}

public extension Path {
    mutating func addCurve(through points: [CGPoint]) {
        guard !points.isEmpty else { return }
        var first: CGPoint?
        var prev: CGPoint = .zero
        var last: Path.Element?
        forEach { element in
            if first == nil {
                first = element.end
            }
            if let point = last?.end {
                prev = point
            }
            last = element
        }
        let controlLine: Tween<CGPoint>?
        switch last {
        case let .line(to):
            controlLine = Tween(prev, to)
        case let .quadCurve(to, control):
            if to == control {
                controlLine = Tween(prev, to)
            } else {
                controlLine = Tween(control, to)
            }
        case let .curve(to, control1, control2):
            if to == control2 {
                controlLine = Tween(control1, to)
            } else {
                controlLine = Tween(control2, to)
            }
        case .move, .closeSubpath, nil:
            controlLine = nil
        }
        if let controlLine {
        } else {}
        for i in 1 ..< points.count {}
    }
}

extension Path.Element {
    var end: CGPoint? {
        switch self {
        case let .line(to):
            return to
        case let .quadCurve(to, _):
            return to
        case let .curve(to, _, _):
            return to
        case let .move(to: to):
            return to
        case .closeSubpath:
            return nil
        }
    }
}

public func arcControlPointLength(
    radius: Double = 1,
    angle: Angle = .degrees(90)
) -> Double {
    let angle = angle.radians.truncatingRemainder(dividingBy: Double.pi * 2)
    return radius * 4 * abs(tan(angle / 4)) / 3
}

public extension Double {
    static let arcControlPointCoefficient = arcControlPointLength()
}
