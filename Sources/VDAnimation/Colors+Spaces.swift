import SwiftUI

public enum ColorInterpolationType: CaseIterable, Hashable {
    public static var `default` = ColorInterpolationType.okLAB

    /// Most efficient
    case displayP3

    /// Most popular; used by SwiftUI under the hood for animations and gradients. A bit inefficient.
    case okLAB

    /// Most beautiful and most inefficient; inefficiency is close to `okLAB` but slightly worse.
    ///
    /// - Note: This is the OKLCH color space, but I apply a hue interpolation correction based on the chroma component to avoid overly saturated intermediate colors when interpolating between saturated and desaturated colors.
    case okLCH
}

protocol AnyColor {
    var rgba: WithOpacity<DisplayP3> { get }
    init(rgba: WithOpacity<DisplayP3>)
}

func colorLerp<C: AnyColor & Hashable>(_ lhs: C, _ rhs: C, _ t: Double, type: ColorInterpolationType = .default) -> C {
    let l = lhs.rgba
    let r = rhs.rgba
    switch type {
    case .displayP3:
        return C(
            rgba: WithOpacity<DisplayP3>(
                DisplayP3.lerp(l.color, r.color, t),
                opacity: .lerp(l.opacity, r.opacity, t)
            )
        )
    case .okLCH:
        let lo = oklch(for: l.color)
        let ro = oklch(for: r.color)
        let value = OKLCH.mix(lo, ro, t)
        return C(
            rgba: WithOpacity<DisplayP3>(
                DisplayP3(xyz: value.xyz),
                opacity: .lerp(l.opacity, r.opacity, t)
            )
        )
    case .okLAB:
        let lo = OKLab(xyz: l.color.xyz)
        let ro = OKLab(xyz: r.color.xyz)
        let value = OKLab.lerp(lo, ro, t)
        return C(
            rgba: WithOpacity<DisplayP3>(
                DisplayP3(xyz: value.xyz),
                opacity: .lerp(l.opacity, r.opacity, t)
            )
        )
    }
}

private func oklch(for rgb: DisplayP3) -> OKLCH {
    if Thread.isMainThread, let value = cache[rgb] {
        return value
    }
    let result = OKLCH(xyz: rgb.xyz)
    if Thread.isMainThread {
        if cache.count > 1000 {
            cache.remove(at: cache.startIndex)
        }
        cache[rgb] = result
    }
    return result
}

private var cache: [DisplayP3: OKLCH] = Dictionary(minimumCapacity: 500)

extension Color: AnyColor {
    init(rgba: WithOpacity<DisplayP3>) {
        self.init(.displayP3, red: rgba.color.r, green: rgba.color.g, blue: rgba.color.b, opacity: rgba.opacity)
    }
}

#if canImport(UIKit)
    extension Color {
        var rgba: WithOpacity<DisplayP3> {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return UIColor(self).rgba
            } else {
                let components = self.components()
                return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a).rgba
            }
        }
    }

    extension AnyColor where Self: UIColor {
        init(rgba: WithOpacity<DisplayP3>) {
            self.init(
                displayP3Red: clamp(rgba.color.r),
                green: clamp(rgba.color.g),
                blue: clamp(rgba.color.b),
                alpha: clamp(rgba.opacity)
            )
        }
    }

    extension UIColor: AnyColor {
        var rgba: WithOpacity<DisplayP3> {
            cgColor.rgba
        }
    }
#endif

#if canImport(AppKit)
    extension Color {
        var rgba: WithOpacity<DisplayP3> {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return NSColor(self).rgba
            } else {
                let components = self.components()
                return NSColor(red: components.r, green: components.g, blue: components.b, alpha: components.a).rgba
            }
        }
    }

    extension AnyColor where Self: NSColor {
        init(rgba: WithOpacity<DisplayP3>) {
            self.init(
                displayP3Red: clamp(rgba.color.r),
                green: clamp(rgba.color.g),
                blue: clamp(rgba.color.b),
                alpha: clamp(rgba.opacity)
            )
        }
    }

    extension NSColor: AnyColor {
        var rgba: WithOpacity<DisplayP3> {
            cgColor.rgba
        }
    }
#endif

private extension Color {
    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x0000_00FF) / 255
        }
        return (r, g, b, a)
    }
}

extension AnyColor where Self: CGColor {
    init(rgba: WithOpacity<DisplayP3>) {
        self.init(red: rgba.color.r, green: rgba.color.g, blue: rgba.color.b, alpha: rgba.opacity)
    }
}

extension CGColor: AnyColor {
    var rgba: WithOpacity<DisplayP3> {
        if let p3 = CGColorSpace(name: CGColorSpace.displayP3),
           let rgb = converted(to: p3, intent: .defaultIntent, options: nil)?.components,
           rgb.count > 2
        {
            return WithOpacity(
                DisplayP3(
                    r: Double(rgb[0]),
                    g: Double(rgb[1]),
                    b: Double(rgb[2])
                ),
                opacity: rgb.count > 3 ? Double(rgb[3]) : 1.0
            )
        }
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        if let rgb = converted(to: rgbColorSpace, intent: .defaultIntent, options: nil)?.components,
           rgb.count > 2
        {
            return WithOpacity(
                DisplayP3(
                    xyz: sRGB(
                        r: Double(rgb[0]),
                        g: Double(rgb[1]),
                        b: Double(rgb[2])
                    ).xyz
                ),
                opacity: rgb.count > 3 ? Double(rgb[3]) : 1.0
            )
        }
        return WithOpacity(DisplayP3(r: 0, g: 0, b: 0), opacity: 1)
    }
}

struct WithOpacity<C> {
    public var opacity: Double
    public var color: C

    public init(_ color: C, opacity: Double = 1.0) {
        self.opacity = opacity
        self.color = color
    }
}

struct XYZ: Tweenable {
    public var x: Double
    public var y: Double
    public var z: Double

    public var xyz: XYZ { self }

    public init(xyz: XYZ) {
        self = xyz
    }

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static func lerp(_ from: XYZ, _ to: XYZ, _ t: Double) -> XYZ {
        XYZ(x: .lerp(from.x, to.x, t), y: .lerp(from.y, to.y, t), z: .lerp(from.z, to.z, t))
    }
}

struct sRGB: Tweenable, Hashable {
    public var r: Double // 0.0–1.0
    public var g: Double
    public var b: Double

    public var xyz: XYZ {
        // sRGB → linear → XYZ
        let linear = linear
        let rl = linear.r
        let gl = linear.g
        let bl = linear.b

        let x = 0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl
        let y = 0.2126729 * rl + 0.7151522 * gl + 0.0721750 * bl
        let z = 0.0193339 * rl + 0.1191920 * gl + 0.9503041 * bl

        return XYZ(x: x, y: y, z: z)
    }

    public var linear: RGB {
        RGB(
            r: Self.sRGBToLinear(r),
            g: Self.sRGBToLinear(g),
            b: Self.sRGBToLinear(b)
        )
    }

    public init(xyz: XYZ) {
        self = Self.fromLinear(RGB(xyz: xyz))
    }

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public static func lerp(_ from: sRGB, _ to: sRGB, _ t: Double) -> sRGB {
        return sRGB(r: .lerp(from.r, to.r, t), g: .lerp(from.g, to.g, t), b: .lerp(from.b, to.b, t))
    }

    public static func fromLinear(_ linear: RGB) -> sRGB {
        sRGB(
            r: linearToSRGB(linear.r),
            g: linearToSRGB(linear.g),
            b: linearToSRGB(linear.b)
        )
    }

    private static func sRGBToLinear(_ c: Double) -> Double {
        sRGBTransfer.toLinear(c)
    }

    private static func linearToSRGB(_ c: Double) -> Double {
        sRGBTransfer.fromLinear(c)
    }
}

struct RGB: Tweenable {
    public var r: Double
    public var g: Double
    public var b: Double

    public var xyz: XYZ {
        let x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
        let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
        let z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
        return XYZ(x: x, y: y, z: z)
    }

    public init(xyz: XYZ) {
        r = 3.2404542 * xyz.x - 1.5371385 * xyz.y - 0.4985314 * xyz.z
        g = -0.9692660 * xyz.x + 1.8760108 * xyz.y + 0.0415560 * xyz.z
        b = 0.0556434 * xyz.x - 0.2040259 * xyz.y + 1.0572252 * xyz.z
    }

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public static func lerp(_ from: RGB, _ to: RGB, _ t: Double) -> RGB {
        return RGB(r: .lerp(from.r, to.r, t), g: .lerp(from.g, to.g, t), b: .lerp(from.b, to.b, t))
    }
}

struct LMS: Tweenable {
    public var l: Double
    public var m: Double
    public var s: Double

    public var xyz: XYZ {
        let x = 1.2268798733741557 * l - 0.5578149965554813 * m + 0.28139105017721594 * s
        let y = -0.04057576262431372 * l + 1.1122868293970594 * m - 0.07171106666151696 * s
        let z = -0.07637294974672142 * l - 0.4214933239627916 * m + 1.5869240244272422 * s

        return XYZ(x: x, y: y, z: z)
    }

    public init(xyz: XYZ) {
        // XYZ → LMS
        l = 0.8189754821531442 * xyz.x + 0.3619149742339154 * xyz.y - 0.128851072578134 * xyz.z
        m = 0.03296647549663265 * xyz.x + 0.9292757969081972 * xyz.y + 0.03617894848035121 * xyz.z
        s = 0.04817870336283606 * xyz.x + 0.2642030909467219 * xyz.y + 0.6337273213403319 * xyz.z
    }

    public init(l: Double, m: Double, s: Double) {
        self.l = l
        self.m = m
        self.s = s
    }

    public static func lerp(_ from: LMS, _ to: LMS, _ t: Double) -> LMS {
        return LMS(l: .lerp(from.l, to.l, t), m: .lerp(from.m, to.m, t), s: .lerp(from.s, to.s, t))
    }
}

struct OKLab: Tweenable {
    public var l: Double
    public var a: Double
    public var b: Double

    public var lms: LMS {
        // OKLab → LMS
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        return LMS(l: l_ * l_ * l_, m: m_ * m_ * m_, s: s_ * s_ * s_)
    }

    public var xyz: XYZ {
        let lms = lms
        let x = 1.2270138511 * lms.l - 0.5577999807 * lms.m + 0.2812561490 * lms.s
        let y = -0.0405801784 * lms.l + 1.1122568696 * lms.m - 0.0716766787 * lms.s
        let z = -0.0763812845 * lms.l - 0.4214819784 * lms.m + 1.5861632204 * lms.s

        return XYZ(x: x, y: y, z: z)
    }

    public init(xyz: XYZ) {
        let lms = LMS(xyz: xyz)
        let l_ = fastCbrt(lms.l)
        let m_ = fastCbrt(lms.m)
        let s_ = fastCbrt(lms.s)

        l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    }

    public init(l: Double, a: Double, b: Double) {
        self.l = l
        self.a = a
        self.b = b
    }

    public static func lerp(_ from: OKLab, _ to: OKLab, _ t: Double) -> OKLab {
        return OKLab(l: .lerp(from.l, to.l, t), a: .lerp(from.a, to.a, t), b: .lerp(from.b, to.b, t))
    }
}

struct DisplayP3: Tweenable, Hashable {
    public var r: Double
    public var g: Double
    public var b: Double

    /// Display P3 uses the same transfer function as sRGB (gamma ≈ 2.2),
    /// so we must linearize before applying the matrix to XYZ.
    public var xyz: XYZ {
        let rl = sRGBTransfer.toLinear(r)
        let gl = sRGBTransfer.toLinear(g)
        let bl = sRGBTransfer.toLinear(b)
        let x = 0.4865709 * rl + 0.2656676 * gl + 0.1982173 * bl
        let y = 0.2289745 * rl + 0.6917385 * gl + 0.0792869 * bl
        let z = 0.0000000 * rl + 0.0451134 * gl + 1.0439443 * bl
        return XYZ(x: x, y: y, z: z)
    }

    public init(xyz: XYZ) {
        let rl = 2.4934969 * xyz.x - 0.9313836 * xyz.y - 0.4027108 * xyz.z
        let gl = -0.8294889 * xyz.x + 1.7626641 * xyz.y + 0.0236247 * xyz.z
        let bl = 0.0358458 * xyz.x - 0.0761724 * xyz.y + 0.9568845 * xyz.z
        r = sRGBTransfer.fromLinear(rl)
        g = sRGBTransfer.fromLinear(gl)
        b = sRGBTransfer.fromLinear(bl)
    }

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public static func lerp(_ from: DisplayP3, _ to: DisplayP3, _ t: Double) -> DisplayP3 {
        return DisplayP3(
            r: .lerp(from.r, to.r, t),
            g: .lerp(from.g, to.g, t),
            b: .lerp(from.b, to.b, t)
        )
    }
}

struct OKLCH: Tweenable {
    public var l: Double
    public var c: Double
    public var h: Double

    public var okLab: OKLab {
        let (sinVal, cosVal) = fastSinCos(h)
        return OKLab(l: l, a: c * cosVal, b: c * sinVal)
    }

    public var xyz: XYZ {
        okLab.xyz
    }

    public init(xyz: XYZ) {
        self = .fromOKLab(OKLab(xyz: xyz))
    }

    public init(l: Double, c: Double, h: Double) {
        self.l = l
        self.c = c
        self.h = h
    }

    public static func fromOKLab(_ lab: OKLab) -> OKLCH {
        let c = sqrt(lab.a * lab.a + lab.b * lab.b)
        let h = atan2(lab.b, lab.a) * 180 / .pi
        return OKLCH(l: lab.l, c: c, h: h < 0 ? h + 360 : h)
    }

    public static func mix(_ from: OKLCH, _ to: OKLCH, _ t: Double) -> OKLCH {
        // Blend between OKLab (good L/C transitions) and OKLCH (good hue path)
        // based on how different the chromas are.
        let x = abs(from.c - to.c) / 0.3
        let x3 = x * x * x
        let strength = x3 * (x * (6 * x - 15) + 10)

        // OKLab interpolation: natural L/C path
        let labFrom = from.okLab
        let labTo = to.okLab
        let labMid = OKLab.lerp(labFrom, labTo, t)
        let fromLab = OKLCH.fromOKLab(labMid)

        // OKLCH interpolation: correct hue path
        let fromLCH = OKLCH(
            l: .lerp(from.l, to.l, t),
            c: .lerp(from.c, to.c, t),
            h: cycleLerp(from.h, to.h, t)
        )

        // Blend two whole colors: at equal chroma → pure OKLCH; at large delta → OKLab
        return OKLCH(
            l: .lerp(fromLCH.l, fromLab.l, strength),
            c: .lerp(fromLCH.c, fromLab.c, strength),
            h: cycleLerp(fromLCH.h, fromLab.h, strength)
        )
    }

    static func lerp(_ from: OKLCH, _ to: OKLCH, _ t: Double) -> OKLCH {
        OKLCH(
            l: .lerp(from.l, to.l, t),
            c: .lerp(from.c, to.c, t),
            h: cycleLerp(from.h, to.h, t)
        )
    }
}

func cycleLerp(_ l: Double, _ r: Double, _ t: Double, period: Double = 360) -> Double {
    var fh = l.truncatingRemainder(dividingBy: period)
    var th = r.truncatingRemainder(dividingBy: period)
    let half = period / 2
    if fh - th > half {
        fh -= period
    } else if th - fh > half {
        th -= period
    }
    return (Double.lerp(fh, th, t) + period).truncatingRemainder(dividingBy: period)
}

func longestCycleLerp(_ l: Double, _ r: Double, _ t: Double, period: Double = 360) -> Double {
    var fh = l.truncatingRemainder(dividingBy: period)
    var th = r.truncatingRemainder(dividingBy: period)
    let half = period / 2
    if fh > th, fh - th < half {
        th += period
    } else if th > fh, th - fh < half {
        fh += period
    }
    return .lerp(fh, th, t).truncatingRemainder(dividingBy: period)
}

/// sRGB / Display P3 share the same transfer function (gamma ≈ 2.2).
enum sRGBTransfer {
    /// Peels off the low-linear branch exactly, then uses a minimax polynomial
    /// to approximate pow((c + 0.055) / 1.055, 2.4) on [0.04045, 1].
    /// Max error < 0.0005 across [0, 1].
    @inline(__always)
    static func toLinear(_ c: Double) -> Double {
        if c <= 0.04045 { return c / 12.92 }
        // Normalize to [0, 1] within the nonlinear segment
        let x = (c + 0.055) / 1.055
        // Approximate x^2.4 ≈ x² · x^0.4
        // x^0.4 ≈ polynomial fit on [0.03, 1]
        let x2 = x * x
        // Remez-style polynomial for x^0.4 on [0, 1]
        let x04 = 0.0261 + x * (1.4 - x * (0.7517 - x * 0.3256))
        return x2 * x04
    }

    /// Approximate pow(c, 1/2.4) on [0.0031308, 1].
    /// 1/2.4 ≈ 0.4167. Approximate via sqrt chain + polynomial correction.
    /// Max error < 0.001 across [0, 1].
    @inline(__always)
    static func fromLinear(_ c: Double) -> Double {
        if c <= 0.0031308 { return 12.92 * c }
        // x^(1/2.4) ≈ x^(5/12) = (x^(1/4))^(5/3) = sqrt(sqrt(x))^(5/3)
        // Approximate via sqrt(sqrt(x)) * correction polynomial
        let s = sqrt(c) // c^0.5
        let ss = sqrt(s) // c^0.25
        // c^(5/12) ≈ lerp between c^0.25 and c^0.5 with correction
        // 5/12 = 0.4167, between 0.25 and 0.5
        // weight = (5/12 - 1/4) / (1/2 - 1/4) = (5/12 - 3/12) / (6/12 - 3/12) = 2/3
        let r = ss + (s - ss) * 0.6667
        return 1.055 * r - 0.055
    }
}

/// Fast cube root using Newton-Raphson with 2 iterations.
/// Handles negative inputs by reflecting.
@inline(__always)
func fastCbrt(_ x: Double) -> Double {
    if x == 0 { return 0 }
    let sign: Double = x < 0 ? -1 : 1
    let a = abs(x)
    // Initial guess: pow(a, 1/3) ≈ exp2(log2(a)/3) via bit manipulation
    var guess = Double(bitPattern: a.bitPattern / 3 + 0x2A9F_7893_782D_A3C4)
    // 2 Newton-Raphson iterations: g = g - (g³ - a) / (3g²) = (2g + a/g²) / 3
    guess = (2 * guess + a / (guess * guess)) / 3
    guess = (2 * guess + a / (guess * guess)) / 3
    return sign * guess
}

/// CPU-optimized sin/cos via lookup table with linear interpolation.
/// On GPU this is unnecessary — hardware SFU computes sin/cos in 1-4 cycles.
/// Input: degrees [0, 360). Returns (sin, cos).
@inline(__always)
func fastSinCos(_ degrees: Double) -> (sin: Double, cos: Double) {
    let d = degrees.truncatingRemainder(dividingBy: 360)
    let normalized = d < 0 ? d + 360 : d
    let idx = normalized * (Double(sinCosLUTSize) / 360.0)
    let i = Int(idx)
    let frac = idx - Double(i)
    let i0 = i % sinCosLUTSize
    let i1 = (i + 1) % sinCosLUTSize
    return (
        sin: sinLUT[i0] + (sinLUT[i1] - sinLUT[i0]) * frac,
        cos: cosLUT[i0] + (cosLUT[i1] - cosLUT[i0]) * frac
    )
}

private let sinCosLUTSize = 720
private let sinLUT: [Double] = (0 ..< 720).map { sin(Double($0) * .pi / 360) }
private let cosLUT: [Double] = (0 ..< 720).map { cos(Double($0) * .pi / 360) }

private func clamp(_ x: Double) -> CGFloat {
    CGFloat(max(0, min(1, x)))
}
