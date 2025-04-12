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

    var distance: CGFloat {
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
//                if isLine {
//                    let middle = CGPoint.lerp(start, end, t)
//                    return Tween(
//                        PathSegment(start: start, end: middle),
//                        PathSegment(start: middle, end: end)
//                    )
//                }

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

        for i in 1..<n {
            let t = step / (1 - step * Double(i - 1))
            let tween = current.divide(at: t)
            segments.append(tween.start)
            current = tween.end
        }
        segments.append(current)
        return segments
    }
}

struct PathShape {
    var segments: [PathSegment]
}

extension [PathSegment] {

    func normalizeStart(rect: CGRect) -> [PathSegment] {
        guard isClosed, count > 1 else { return self }
        var mostZero: Int?

        for i in 0..<count {
            if let v = mostZero {
                if self[i].start.zeronest(in: rect) < self[v].start.zeronest(in: rect) {
                    mostZero = i
                }
            } else {
                mostZero = i
            }
        }
        if let mostZero {
            let result = Array(self[mostZero...] + self[0 ..< mostZero])
            return result
        }
        return self
    }
}

extension CGPath: Tweenable {
    func toSegments() -> [[PathSegment]] {
        var segments: [[PathSegment]] = []
        var lastPoint: CGPoint = .zero
        var mostLeft: Int?
        var mostZero: Int?

        func append(_ segment: PathSegment) {
            guard segment.start != segment.end || !segment.isLine else { return }
            if segments.isEmpty {
                segments.append([])
            }

            let last = segments[segments.count - 1]

            func small<T: Comparable>(_ kp: (CGPoint) -> T, to value: inout Int?) {
                if let v = value {
                    if kp(segment.start) < kp(last[v].start) {
                        value = last.count
                    }
                } else {
                    value = last.count
                }
            }

            small(\.x, to: &mostLeft)
            small({ $0.zeronest(in: boundingBox) }, to: &mostZero)

            segments[segments.count - 1].append(segment)
        }

        applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint:
                lastPoint = e.points[0]
                if segments.last?.isEmpty != true {
                    segments.append([])
                }
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
                if let first = segments.last?.first?.start, lastPoint != first {
                    append(PathSegment(start: lastPoint, end: first))
                }
                var last = segments[segments.count - 1]
                if let mostZero, last.count > 1 {
                    segments[segments.count - 1] = Array(last[mostZero...] + last[0 ..< mostZero])
                    last = segments[segments.count - 1]
                    if let ml = mostLeft {
                        mostLeft = (ml + last.count - mostZero) % last.count
                    }
                }
                if let mostLeft, last.count > 1 {
                    let point = last[mostLeft].start
                    let next = last[mostLeft].end
                    let prev = last[(mostLeft + last.count - 1) % last.count].start
                    let isClockwise = tg(point, next) > tg(point, prev)
                    if !isClockwise {
                        segments[segments.count - 1] = last.reversed().map(\.reversed)
                        last = segments[segments.count - 1]
                    }
                }
                mostLeft = nil
                mostZero = nil
            @unknown default:
                break
            }
        }
        return segments.filter { !$0.isEmpty }
    }

    public static func lerp(_ p1: CGPath, _ p2: CGPath, _ t: Double) -> Self {
        var result: Tween<[[PathSegment]]>

        if Thread.isMainThread, let value = cache[Tween(p1, p2)] {
            result = value
        } else {
            let array1 = p1.toSegments()
            let array2 = p2.toSegments()
            result = Tween([], [])
            for i in 0..<max(array1.count, array2.count) {
                var s1 = array1[i % array1.count]
                var s2 = array2[i % array2.count] // TODO: match closest pathes
                if s1.isClosed != s2.isClosed {
                    if !s1.isClosed {
                        s1 += s1.reversed().map(\.reversed)
                    } else {
                        s2 += s2.reversed().map(\.reversed)
                    }
                }
                
                let t1 = s1.map { ($0, $0.distance) }
                let t2 = s2.map { ($0, $0.distance) }
                
                let total1 = t1.reduce(0.0) { $0 + $1.1 }
                let total2 = t2.reduce(0.0) { $0 + $1.1 }
                let count = max(50, s1.count, s2.count, Int(total1 / 3), Int(total2 / 3))
                result.start.append(
                    unifySegments(t1, total: total1, count: count, in: p1.boundingBox).normalizeStart(rect: p1.boundingBox)
                )
                result.end.append(
                    unifySegments(t2, total: total2, count: count, in: p2.boundingBox).normalizeStart(rect: p2.boundingBox)
                )
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
            for j in 0 ..< result.start[i].count {
                let segment = PathSegment.lerp(result.start[i][j], result.end[i][j], t)
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

    private static var cache: [Tween<CGPath>: Tween<[[PathSegment]]>] = [:]

    private static func unifySegments(_ segments: [(PathSegment, CGFloat)], total: CGFloat, count: Int, in _: CGRect) -> [PathSegment] {
        guard segments.count < count else { return segments.map(\.0) }
        var result: [PathSegment] = []
        let needAdd = count - segments.count
        for i in segments.indices {
            var cnt = 1 + Int(CGFloat(needAdd) * segments[i].1 / total)
            if i == segments.count - 1 {
                cnt = count - result.count
            }
            result += segments[i].0.split(into: cnt)
        }
        return result
    }

    private static func mergeSegments(_ original: [PathSegment], as reference: [PathSegment]) -> [PathSegment] {
        guard reference.count > original.count else { return original }
        var result: [PathSegment] = []

        let maxCount = max(reference.count, original.count)
//        let minCount = min(reference.count, original.count)
//        let finalCount = maxCount + minCount
        let finalCount = maxCount

        // let step = max(1, result.count / (finalCount - result.count))

        let distances0 = original.map(\.distance)
        let distances1 = reference.map(\.distance)

        let total0 = distances0.reduce(0, +)
        let total1 = distances1.reduce(0, +)

        let percent0 = distances0.map { $0 / total0 }
        let percent1 = distances1.map { $0 / total1 }

        var i = 0

        // now we need to add some segments to the original path according to the lengths
        var j = 0
        var offset = 0.0
        var refOffset = 0.0
        while i < original.count, result.count < finalCount, j < reference.count {
            let segment = original[i]
            let length = percent0[i]
            var parts: [PathSegment] = [segment]
            var lastOffset = offset
            var lastLength = length
            while refOffset < offset + length, j < reference.count {
                let refLength = percent1[j]
                refOffset += refLength
                let t = (refOffset - lastOffset) / lastLength
                if t < 1 {
                    let tween = parts.last!.divide(at: t)
                    parts.removeLast()
                    parts.append(tween.start)
                    parts.append(tween.end)
                    lastLength = tween.end.distance / total0
                    lastOffset += tween.start.distance / total0
                    j += 1
                }
            }
            result += parts
            offset += length
            i += 1
        }
//        print(result.count, finalCount)

        
//        return reference

        // var inserted: [Int: Int] = [:]
        // while result.count < finalCount {
        //     let j = i % original.count
        //     let value = original[j]
        //     let k = (j + inserted.filter { $0.key < j }.values.reduce(0, +)) % result.count
        //     let n = inserted[j, default: 0] + 1
        //     result.replaceSubrange(k ..< (k + n), with: value.split(into: n + 1))
        //     inserted[j] = n
        //     i += step
        // }

        return result
    }
}

extension [PathSegment] {
    var isClosed: Bool {
        last?.end == first?.start
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

struct PathAnimation: View {
    @MotionState var path = Self.makeHeartPath(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    var body: some View {
        VStack {
            WithMotion(_path) { path in
                Path(path).fill()
            } motion: {
                To(
                    Self.makeStarPath(center: CGPoint(x: 50, y: 50), radius: 50, points: 5)
                )
                .duration(0.3)
            }
            .frame(width: 100, height: 200)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            Slider(value: _path.$progress)
            Button("Play") {
                if $path.progress == 1 {
                    $path.reverse()
                } else {
                    $path.play(from: 0, to: 1)
                }
            }
        }
    }

    static func makeStarPath(center: CGPoint, radius: CGFloat, points: Int) -> CGPath {
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
        return path
    }

    static func makeRectPath(rect: CGRect) -> CGPath {
        return CGPath(roundedRect: rect, cornerWidth: 30, cornerHeight: 30, transform: nil)
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
//        path.addLine(to: .zero)
//        path.closeSubpath()
        return path
    }

    static func makeHeartPath(in rect: CGRect) -> CGPath {
        UIBezierPath(heartIn: rect).cgPath
    }
}

enum PathPreview: PreviewProvider {
    static var previews: some View {
        PathAnimation()
    }
}

extension CGPoint {

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    var length: CGFloat {
        return sqrt(x * x + y * y)
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

extension UIBezierPath {
    convenience init(heartIn rect: CGRect) {
        self.init()

        // Calculate Radius of Arcs using Pythagoras
        let sideOne = rect.width * 0.4
        let sideTwo = rect.height * 0.3
        let arcRadius = sqrt(sideOne * sideOne + sideTwo * sideTwo) / 2

        // Left Hand Curve
        addArc(withCenter: CGPoint(x: rect.width * 0.3, y: rect.height * 0.35), radius: arcRadius, startAngle: 135.degreesToRadians, endAngle: 315.degreesToRadians, clockwise: true)

        // Top Centre Dip
        addLine(to: CGPoint(x: rect.width / 2, y: rect.height * 0.2))

        // Right Hand Curve
        addArc(withCenter: CGPoint(x: rect.width * 0.7, y: rect.height * 0.35), radius: arcRadius, startAngle: 225.degreesToRadians, endAngle: 45.degreesToRadians, clockwise: true)

        // Right Bottom Line
        addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.95))

        // Left Bottom Line
        close()
    }
}

extension Int {
    var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}
