import CoreGraphics
import SwiftUI

extension Path: Tweenable {

    public static func lerp(_ lhs: Path, _ rhs: Path, _ t: Double) -> Path {
        Path(CGPath.lerp(lhs.cgPath, rhs.cgPath, t))
    }
}

#if canImport(UIKit)
    extension UIBezierPath: Tweenable {
        public static func lerp(_ lhs: UIBezierPath, _ rhs: UIBezierPath, _ t: Double) -> Self {
            Self(cgPath: .lerp(lhs.cgPath, rhs.cgPath, t))
        }
    }
#endif

#if canImport(AppKit)
    @available(macOS 14.0, *)
    extension NSBezierPath: Tweenable {
        public static func lerp(_ lhs: NSBezierPath, _ rhs: NSBezierPath, _ t: Double) -> Self {
            Self(cgPath: .lerp(lhs.cgPath, rhs.cgPath, t))
        }
    }
#endif

extension CGPath: Tweenable {

    public static func lerp(_ p1: CGPath, _ p2: CGPath, _ t: Double) -> Self {
        var result: Tween<[PathShape]>

        if Thread.isMainThread, let value = cache[Tween(p1, p2)] {
            result = value
        } else {
            let array1 = p1.toSegments()
            let array2 = p2.toSegments()
            result = Tween([], [])
            for i in 0 ..< max(array1.count, array2.count) {
                var s1 = array1[i % array1.count]
                var s2 = array2[i % array2.count] // TODO: match closest pathes
                if s1.isClosed != s2.isClosed {
                    if !s1.isClosed {
                        s1.segments += s1.segments.reversed().map(\.reversed)
                    } else {
                        s2.segments += s2.segments.reversed().map(\.reversed)
                    }
                }

                let t1 = s1.segments.map { ($0, $0.length) }
                let t2 = s2.segments.map { ($0, $0.length) }

                let total1 = t1.reduce(0.0) { $0 + $1.1 }
                let total2 = t2.reduce(0.0) { $0 + $1.1 }
                let count = max(50, s1.segments.count, s2.segments.count, Int(total1 / 3), Int(total2 / 3))

                s1.unifySegments(t1, total: total1, count: count)
                s2.unifySegments(t2, total: total2, count: count)

                result.start.append(s1)
                result.end.append(s2)
            }

            if Thread.isMainThread {
                if cache.count > 1000 {
                    cache.remove(at: cache.startIndex)
                }
                cache[Tween(p1, p2)] = result
            }
        }

        let path = CGMutablePath()
        for i in 0 ..< result.start.count {
            for j in 0 ..< result.start[i].segments.count {
                let segment = PathSegment.lerp(result.start[i].segments[j], result.end[i].segments[j], t)
                if j == 0 {
                    path.move(to: segment.start)
                }
                path.addLine(to: segment.end)
            }
            if result.start[i].isClosed || result.end[i].isClosed {
                path.closeSubpath()
            }
        }
        return path as! Self
    }
    
    private func toSegments() -> [PathShape] {
        var shapes: [PathShape] = []
        var lastPoint: CGPoint = .zero
        var mostLeftStart: (Int, KeyPath<PathSegment, CGPoint>)?
        var mostLeft: (Int, KeyPath<PathSegment, CGPoint>)?
        var mostTop: (Int, KeyPath<PathSegment, CGPoint>)?
        var mostBottom: (Int, KeyPath<PathSegment, CGPoint>)?
        var mostRight: (Int, KeyPath<PathSegment, CGPoint>)?
        var closed = true

        func append(_ segment: PathSegment) {
            guard segment.start != segment.end || !segment.isLine else { return }
            closed = false
            if shapes.isEmpty {
                shapes.append(PathShape(segments: [], bounds: .zero))
            }

            let last = shapes[shapes.count - 1]

            func most<T: Comparable>(
                _ compare: @escaping (T, T) -> Bool,
                _ kp: (CGPoint) -> T,
                _ points: [KeyPath<PathSegment, CGPoint>] = [\.start, \.end, \.cpt0, \.cpt1],
                to value: inout (Int, KeyPath<PathSegment, CGPoint>)?
            ) {
                guard !last.segments.isEmpty else { return }
                let current = value?.0 ?? 0
                for p in points {
                    if compare(kp(segment[keyPath: p]), kp(last.segments[current][keyPath: p])) {
                        value = (last.segments.count, p)
                    }
                }
            }
            
            most(<, \.x, [\.start], to: &mostLeftStart)
            most(<, \.x, to: &mostLeft)
            most(<, \.y, to: &mostTop)
            most(>, \.x, to: &mostRight)
            most(>, \.y, to: &mostBottom)

            shapes[shapes.count - 1].segments.append(segment)
        }

        func close() {
            guard !closed else { return }
            defer { closed = true }
            if let first = shapes.last?.segments.first?.start, lastPoint != first {
                append(PathSegment(start: lastPoint, end: first))
            }
            let last = shapes[shapes.count - 1].segments
            if let mostLeftStart = mostLeftStart?.0, last.count > 1 {
                let point = last[mostLeftStart].start
                let next = last[mostLeftStart].end
                let prev = last[(mostLeftStart + last.count - 1) % last.count].start
                let isClockwise = tg(point, next) > tg(point, prev)
                if !isClockwise {
                    shapes[shapes.count - 1].reverse()
                }
            }
            let origin = CGPoint(
                x: mostLeft.map { last[$0.0][keyPath: $0.1].x } ?? 0,
                y: mostTop.map { last[$0.0][keyPath: $0.1].y } ?? 0
            )
            shapes[shapes.count - 1].bounds = boundingBox
//            CGRect(
//                origin: origin,
//                size: CGSize(
//                    width: mostRight.map { last[$0.0][keyPath: $0.1].x - origin.x } ?? boundingBox.width,
//                    height: mostBottom.map { last[$0.0][keyPath: $0.1].y - origin.y } ?? boundingBox.height
//                )
//            )
            mostLeftStart = nil
            mostLeft = nil
            mostTop = nil
            mostBottom = nil
            mostRight = nil
        }

        applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint:
                lastPoint = e.points[0]
            case .addLineToPoint:
                let end = e.points[0]
                append(PathSegment(start: lastPoint, end: end))
                lastPoint = end
            case .addCurveToPoint:
                // Cubic Bezier curve (has two control points)
                let cp1 = e.points[0]
                let cp2 = e.points[1]
                let end = e.points[2]
                append(PathSegment(start: lastPoint, end: end, cpt: (cp1, cp2)))
                lastPoint = end
            case .addQuadCurveToPoint:
                // Quadratic Bezier curve (has one control point)
                let cp = e.points[0]
                let end = e.points[1]
                append(PathSegment(start: lastPoint, end: end, cpt: cp))
            case .closeSubpath:
                close()
            @unknown default:
                break
            }
        }
        close()

        return shapes.filter { !$0.segments.isEmpty }
    }


    private static var cache: [Tween<CGPath>: Tween<[PathShape]>] = [:]
}

struct PathShape {
    var segments: [PathSegment]
    var bounds: CGRect

    var isClosed: Bool {
        segments.last?.end == segments.first?.start
    }

    mutating func unifySegments(_ segments: [(PathSegment, CGFloat)], total: CGFloat, count: Int) {
        guard segments.count < count else { return }
        var result: [PathSegment] = []
        let needAdd = count - segments.count
        for i in segments.indices {
            var cnt = 1 + Int(CGFloat(needAdd) * segments[i].1 / total)
            if i == segments.count - 1 {
                cnt = count - result.count
            }
            result += segments[i].0.split(into: cnt)
        }
        self.segments = result
        normalizeStart()
    }

    mutating func normalizeStart() {
        guard isClosed, segments.count > 1 else { return }
        var mostZero: Int?

        for i in 0 ..< segments.count {
            if let v = mostZero {
                if segments[i].start.zeronest(in: bounds) < segments[v].start.zeronest(in: bounds) {
                    mostZero = i
                }
            } else {
                mostZero = i
            }
        }
        
        if let mostZero {
            segments = Array(segments[mostZero...] + segments[0 ..< mostZero])
        }
    }

    mutating func reverse() {
        segments = segments.reversed().map(\.reversed)
    }
}

struct PathSegment: Hashable, Tweenable, CustomStringConvertible {
    let start: CGPoint
    let end: CGPoint
    let cpt: Tween<CGPoint>

    var cpt0: CGPoint { cpt.start }
    var cpt1: CGPoint { cpt.end }

    var isLine: Bool {
        start == cpt.start && end == cpt.end
    }

    var description: String {
        if isLine {
            return String(format: "((%.3f, %.3f), (%.3f, %.3f))", start.x, start.y, end.x, end.y)
        }
        return String(
            format: "((%.3f, %.3f), (%.3f, %.3f), (%.3f, %.3f), (%.3f, %.3f))",
            start.x, start.y, cpt0.x, cpt0.y, cpt1.x, cpt1.y, end.x, end.y
        )
    }

    var reversed: PathSegment {
        PathSegment(start: end, end: start, cpt: (cpt1, cpt0))
    }

    var length: CGFloat {
        let chord = (end - start).length
        let cont_net = (start - cpt0).length + (cpt1 - cpt0).length + (end - cpt1).length
        return (cont_net + chord) / 2
    }

    init(
        start: CGPoint,
        end: CGPoint,
        cpt: (CGPoint, CGPoint)
    ) {
        self.start = start
        self.end = end
        self.cpt = Tween(cpt.0, cpt.1)
    }

    init(start: CGPoint, end: CGPoint, cpt: CGPoint) {
        self.init(
            start: start,
            end: end,
            cpt: (
                .lerp(start, cpt, 2.0 / 3.0),
                .lerp(end, cpt, 2.0 / 3.0)
            )
        )
    }

    init(start: CGPoint, end: CGPoint) {
        self.init(
            start: start,
            end: end,
            cpt: (start, end)
        )
    }

    static func lerp(_ lhs: PathSegment, _ rhs: PathSegment, _ t: Double) -> PathSegment {
        if lhs.isLine, rhs.isLine {
            return PathSegment(
                start: .lerp(lhs.start, rhs.start, t),
                end: .lerp(lhs.end, rhs.end, t)
            )
        }
        return PathSegment(
            start: .lerp(lhs.start, rhs.start, t),
            end: .lerp(lhs.end, rhs.end, t),
            cpt: (
                .lerp(lhs.cpt0, rhs.cpt0, t),
                .lerp(lhs.cpt1, rhs.cpt1, t)
            )
        )
    }

    func point(at t: Double) -> CGPoint {
        if isLine {
            return .lerp(start, end, t)
        }
        // Ensure t is between 0 and 1
        let t = max(0, min(1, t))

        // Calculate using the cubic Bezier formula:
        // B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃

        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT

        let tSquared = t * t
        let tCubed = tSquared * t

        let x = oneMinusTCubed * start.x +
            3 * oneMinusTSquared * t * cpt0.x +
            3 * oneMinusT * tSquared * cpt1.x +
            tCubed * end.x

        let y = oneMinusTCubed * start.y +
            3 * oneMinusTSquared * t * cpt0.y +
            3 * oneMinusT * tSquared * cpt1.y +
            tCubed * end.y

        return CGPoint(x: x, y: y)
    }

    @inlinable
    func divide(at t: Double) -> Tween<PathSegment> {
        let t = max(0, min(1, t))
        if isLine {
            let middle = CGPoint.lerp(start, end, t)
            return Tween(
                PathSegment(start: start, end: middle),
                PathSegment(start: middle, end: end)
            )
        }

        // De Casteljau algorithm for subdivision
        let p0 = start
        let p1 = cpt0
        let p2 = cpt1
        let p3 = end

        // First level
        let p01 = CGPoint.lerp(p0, p1, t)
        let p12 = CGPoint.lerp(p1, p2, t)
        let p23 = CGPoint.lerp(p2, p3, t)

        // Second level
        let p012 = CGPoint.lerp(p01, p12, t)
        let p123 = CGPoint.lerp(p12, p23, t)

        // Final point - this is the point on the curve at parameter t
        let p0123 = CGPoint.lerp(p012, p123, t)

        return Tween(
            PathSegment(start: p0, end: p0123, cpt: (p01, p012)),
            PathSegment(start: p0123, end: p3, cpt: (p123, p23))
        )
    }

    func split(into n: Int) -> [PathSegment] {
        guard n > 0 else { return [] }
        guard n > 1 else { return [self] }

        let step = 1.0 / Double(n)
        var segments: [PathSegment] = []
        var current = self

        for i in 1 ..< n {
            let t = step / (1 - step * Double(i - 1))
            let tween = current.divide(at: t)
            segments.append(tween.start)
            current = tween.end
        }
        segments.append(current)
        return segments
    }
}

extension CGPoint {

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    var length: CGFloat {
        sqrt(x * x + y * y)
    }

    func zeronest(in rect: CGRect) -> CGFloat {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle = atan2(y - center.y, x - center.x)
        return abs(angle + .pi / 2)
    }
}

private func tg(_ p0: CGPoint, _ p1: CGPoint) -> CGFloat {
    let dy = p1.y - p0.y
    if p1.x == p0.x {
        return dy < 0 ? -.infinity : .infinity
    }
    return dy / (p1.x - p0.x)
}
