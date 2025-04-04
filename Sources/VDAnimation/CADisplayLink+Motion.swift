import SwiftUI

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
public final class MotionDisplayLink<Value>: AnimationDriver {

    public var initialValue: Value {
        didSet {
            info = nil
        }
    }

    public var motion: AnyMotion<Value> {
        didSet {
            info = nil
        }
    }

    /// The current progress of the animation (between 0.0 and 1.0)
    public var progress: Double {
        get { _progress }
        set { set(progress: newValue) }
    }

    /// Indicates whether an animation is currently in progress
    public var isAnimating: Bool {
        get { !isStopped && !link.isPaused }
        set {
            if newValue {
                play()
            } else {
                pause()
            }
        }
    }

    public var currentValue: Value {
        prepareIfNeeded().lerp(initialValue, _progress)
    }

    private var _progress = 0.0

    private let apply: (Value) -> Void
    private var info: MotionData<Value>?
    private var repeatForever = false

    private lazy var weakSelf = WeakTarget(self)
    private lazy var link = deinitLink.link
    private lazy var deinitLink = Deiniter(createLink())
    private var isStopped = true
    private var lastRenderTimestamp: CFTimeInterval = 0
    private var animationStartTime: CFTimeInterval = 0
    private var progressTween = Tween(0.0, 1.0)
    private var completions: [() -> Void] = []
    #if canImport(AppKit)
    private weak var source: CADisplayLinkSource?
    #endif

    #if canImport(AppKit)
    public init(
        for source: CADisplayLinkSource,
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) {
        self.apply = apply
        self.initialValue = initialValue
        self.motion = motion()
        self.source = source
        source.links[ObjectIdentifier(self)] = self
    }
    #else
    public init(
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) {
        self.apply = apply
        self.initialValue = initialValue
        self.motion = motion()
    }
    #endif

    /// Plays the animation from a specified progress value to another
    /// - Parameters:
    ///   - from: The starting progress value (defaults to current progress if nil)
    ///   - to: The ending progress value (defaults to current state's end value if nil)
    ///   - repeatForever: Whether the animation should repeat indefinitely
    public func play(
        from: Double? = nil,
        to progress: Double? = nil,
        repeat repeatForever: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        self.repeatForever = repeatForever
        progressTween = Tween(from ?? _progress, progress ?? progressTween.end)
        if let completion {
            completions.append(completion)
        }
        if isStopped {
            isStopped = false
            link.add(to: .main, forMode: .common)
        }
        if link.isPaused {
            link.isPaused = false
        }
    }

    /// Reverses the animation direction
    /// - Parameter from: The starting progress value (defaults to current progress if nil)
    public func reverse(from: Double? = nil) {
        play(
            from: from,
            to: progressTween.end > progressTween.start && _progress != 0.0 || _progress == 1.0 ? 0.0 : 1.0
        )
    }

    /// Toggles the animation state between playing and paused
    public func toggle() {
        if link.isPaused || isStopped {
            play()
        } else {
            pause()
        }
    }

    /// Sets the animation directly to a specific progress value without animating
    /// - Parameter progress: The progress value to set (between 0.0 and 1.0)
    public func set(progress: Double) {
        _progress = progress
        apply(prepareIfNeeded().lerp(initialValue, progress))
    }

    /// Pauses the animation at the current progress
    public func pause() {
        link.isPaused = true
    }

    /// Stops the animation and resets to a specific progress value
    /// - Parameter progress: The progress value to stop at (defaults to 0.0)
    public func stop(at progress: Double = 0) {
        link.isPaused = true
        link.remove(from: .main, forMode: .common)
        isStopped = true
        set(progress: progress)
        lastRenderTimestamp = 0
        notifyCompletions()
    }

    private func prepareIfNeeded() -> MotionData<Value> {
        guard info == nil else { return info! }
        info = motion.prepare(initialValue, nil)
        return info!
    }

    private func tick(_ link: CADisplayLink) {
        // Если это первый кадр
        guard lastRenderTimestamp != 0 else {
            animationStartTime = link.timestamp
            lastRenderTimestamp = link.timestamp
            set(progress: progressTween.start)
            return
        }
        let data = prepareIfNeeded()

        let duration = data.duration?.seconds ?? .defaultAnimationDuration

        let elapsed = link.targetTimestamp - animationStartTime
        var progress = elapsed / duration
        if repeatForever {
            progress = progress.truncatingRemainder(dividingBy: abs(progressTween.end - progressTween.start))
        }
        let isForward = progressTween.end >= progressTween.start
        if !isForward {
            progress = -progress
        }
        let lastProgress = _progress
        _progress = progressTween.start + progress
    
        defer {
            DispatchQueue.main.async { [self, _progress] in
                if let effects = data.sideEffects?(min(lastProgress, _progress)...max(lastProgress, _progress)) {
                    for effect in effects {
                        effect(currentValue)
                    }
                }
            }
        }
    
        let isCompleted = isForward ? _progress >= progressTween.end : _progress <= progressTween.end
        
        if isCompleted, !repeatForever {
            stop(at: progressTween.end)
        } else {
            apply(data.lerp(initialValue, _progress))
            lastRenderTimestamp = link.timestamp
        }
    }

    private func createLink() -> CADisplayLink {
        #if canImport(UIKit)
        let link = CADisplayLink(target: weakSelf, selector: #selector(WeakTarget.tick))
        link.preferredFramesPerSecond = 60
        return link
        #elseif canImport(AppKit)
        return source?.displayLink(target: weakSelf, selector: #selector(WeakTarget.tick)) ?? CADisplayLink()
        #endif
    }

    private func notifyCompletions() {
        completions.forEach { $0() }
        completions.removeAll()
    }

    @MainActor
    private final class WeakTarget: NSObject {

        weak var link: MotionDisplayLink?

        init(_ link: MotionDisplayLink) {
            self.link = link
        }

        @objc func tick(_ link: CADisplayLink) {
            self.link?.tick(link)
        }
    }
}

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
private final class Deiniter {

    let link: CADisplayLink

    init(_ link: CADisplayLink) {
        self.link = link
    }

    deinit {
        link.isPaused = true
        link.invalidate()
    }
}

#if canImport(UIKit)
@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension MotionDisplayLink where Value == Double {

    public convenience init(
        _ apply: @escaping (Value) -> Void
    ) {
        self.init(0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }
}

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
extension NSObject {

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionDisplayLink(
        _ apply: @escaping (Double) -> Void
    ) -> MotionDisplayLink<Double> {
        motionDisplayLink(0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionDisplayLink<Value>(
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> MotionDisplayLink<Value> {
        let link = MotionDisplayLink(initialValue, apply, motion: motion)
        links[ObjectIdentifier(link)] = link
        return link
    }
}
#endif

#if canImport(AppKit)
@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension MotionDisplayLink where Value == Double {

    public convenience init(
        for source: CADisplayLinkSource,
        _ apply: @escaping (Value) -> Void
    ) {
        self.init(for: source, 0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }
}

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
extension CADisplayLinkSource {

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionDisplayLink(
        _ apply: @escaping (Double) -> Void
    ) -> MotionDisplayLink<Double> {
        motionDisplayLink(0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionDisplayLink<Value>(
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> MotionDisplayLink<Value> {
        let link = MotionDisplayLink(for: self, initialValue, apply, motion: motion)
        links[ObjectIdentifier(link)] = link
        return link
    }
}
#endif

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension NSObject {

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func removeMotion<Value>(_ motion: MotionDisplayLink<Value>) {
        links.removeValue(forKey: ObjectIdentifier(motion))
    }

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func removeAllMotions() {
        links.removeAll()
    }

    fileprivate var links: [ObjectIdentifier: Any] {
        get {
            (objc_getAssociatedObject(self, &motionsKey) as? [ObjectIdentifier: Any]) ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &motionsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var motionsKey = 0

#if canImport(AppKit)
@available(macOS 14.0, *)
public protocol CADisplayLinkSource: NSObject {
    @MainActor
    func displayLink(target: Any, selector: Selector) -> CADisplayLink
}

extension NSView: CADisplayLinkSource {}
extension NSWindow: CADisplayLinkSource {}
extension NSScreen: CADisplayLinkSource {}
#endif
