import SwiftUI

// MARK: - FrameLink

/// Abstraction over frame-driven update sources (`CADisplayLink`, `UIUpdateLink`).
///
/// ```swift
/// let link: FrameLink = source.makeFrameLink { ts, targetTs in … }
/// link.activate()
/// link.isPaused = true
/// link.invalidate()
/// ```
@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
public protocol FrameLink: AnyObject {

    /// Pauses or resumes frame callbacks.
    var isPaused: Bool { get set }

    /// Starts delivering frame callbacks.
    func activate()

    /// Stops delivering frame callbacks and releases resources.
    /// The link must not be reused after invalidation.
    func invalidate()
}

// MARK: - FrameLinkSource

/// A source that can drive frame-by-frame animation updates.
///
/// On UIKit, `UIView` and `UIWindowScene` conform to this protocol.
/// On AppKit, `NSView`, `NSWindow`, and `NSScreen` conform.
///
/// ```swift
/// let link = MotionFrameLink(for: myView, 0.0, { value in
///     myView.alpha = CGFloat(value)
/// }) {
///     To(1.0).duration(0.3)
/// }
/// ```
@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
public protocol FrameLinkSource: NSObject {

    /// Creates a frame link that calls `tick` on every frame.
    func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink
}

// MARK: - CADisplayLinkAdapter

/// UIKit-only `FrameLink` backed by `CADisplayLink`.
#if canImport(UIKit)
@available(iOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
private final class CADisplayLinkAdapter: FrameLink {

    private let tick: (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    private var link: CADisplayLink?
    private lazy var target = Target(self)

    init(tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void) {
        self.tick = tick
    }

    var isPaused: Bool {
        get { link?.isPaused ?? true }
        set { link?.isPaused = newValue }
    }

    func activate() {
        guard link == nil else { return }
        let displayLink = CADisplayLink(target: target, selector: #selector(Target.handleTick))
        displayLink.add(to: .main, forMode: .common)
        link = displayLink
    }

    func invalidate() {
        link?.isPaused = true
        link?.remove(from: .main, forMode: .common)
        link?.invalidate()
        link = nil
    }

    @MainActor
    private final class Target: NSObject {
        weak var adapter: CADisplayLinkAdapter?

        init(_ adapter: CADisplayLinkAdapter) {
            self.adapter = adapter
        }

        @objc func handleTick(_ link: CADisplayLink) {
            adapter?.tick(link.timestamp, link.targetTimestamp)
        }
    }
}
#endif

// MARK: - UIUpdateLinkAdapter

#if canImport(UIKit)
/// Wraps `UIUpdateLink` (iOS 18+) behind the `FrameLink` protocol.
@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
@MainActor
private final class UIUpdateLinkAdapter: FrameLink {

    private let tick: (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    private let updateLink: UIUpdateLink

    init(
        updateLink: UIUpdateLink,
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) {
        self.tick = tick
        self.updateLink = updateLink
        updateLink.requiresContinuousUpdates = true
        updateLink.isEnabled = false
        updateLink.addAction { [weak self] _, info in
            self?.tick(info.modelTime, info.estimatedPresentationTime)
        }
    }

    var isPaused: Bool {
        get { !updateLink.isEnabled }
        set { updateLink.isEnabled = !newValue }
    }

    func activate() {
        updateLink.isEnabled = true
    }

    func invalidate() {
        updateLink.isEnabled = false
    }
}
#endif

// MARK: - FrameLinkSource conformances

#if canImport(UIKit)
@available(iOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension UIView: FrameLinkSource {

    public func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink {
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            return UIUpdateLinkAdapter(updateLink: UIUpdateLink(view: self), tick: tick)
        }
        return CADisplayLinkAdapter(tick: tick)
    }
}

@available(iOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension UIWindowScene: FrameLinkSource {

    public func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink {
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            return UIUpdateLinkAdapter(updateLink: UIUpdateLink(windowScene: self), tick: tick)
        }
        return CADisplayLinkAdapter(tick: tick)
    }
}
#endif

#if canImport(AppKit)
/// AppKit-specific `FrameLink` that creates `CADisplayLink` via a provided factory.
@available(macOS 14.0, *)
@MainActor
private final class AppKitDisplayLinkAdapter: FrameLink {

    private let tick: (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    private let createDisplayLink: @MainActor (Any, Selector) -> CADisplayLink
    private var link: CADisplayLink?
    private lazy var target = Target(self)

    init(
        createDisplayLink: @escaping @MainActor (Any, Selector) -> CADisplayLink,
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) {
        self.createDisplayLink = createDisplayLink
        self.tick = tick
    }

    var isPaused: Bool {
        get { link?.isPaused ?? true }
        set { link?.isPaused = newValue }
    }

    func activate() {
        guard link == nil else { return }
        let displayLink = createDisplayLink(target, #selector(Target.handleTick))
        displayLink.add(to: .main, forMode: .common)
        link = displayLink
    }

    func invalidate() {
        link?.isPaused = true
        link?.remove(from: .main, forMode: .common)
        link?.invalidate()
        link = nil
    }

    @MainActor
    private final class Target: NSObject {
        weak var adapter: AppKitDisplayLinkAdapter?

        init(_ adapter: AppKitDisplayLinkAdapter) {
            self.adapter = adapter
        }

        @objc func handleTick(_ link: CADisplayLink) {
            adapter?.tick(link.timestamp, link.targetTimestamp)
        }
    }
}

@available(macOS 14.0, *)
extension NSView: FrameLinkSource {

    public func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink {
        AppKitDisplayLinkAdapter(
            createDisplayLink: { [weak self] target, selector in
                self?.displayLink(target: target, selector: selector) ?? CADisplayLink()
            },
            tick: tick
        )
    }
}

@available(macOS 14.0, *)
extension NSWindow: FrameLinkSource {

    public func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink {
        AppKitDisplayLinkAdapter(
            createDisplayLink: { [weak self] target, selector in
                self?.displayLink(target: target, selector: selector) ?? CADisplayLink()
            },
            tick: tick
        )
    }
}

@available(macOS 14.0, *)
extension NSScreen: FrameLinkSource {

    public func makeFrameLink(
        tick: @escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void
    ) -> any FrameLink {
        AppKitDisplayLinkAdapter(
            createDisplayLink: { [weak self] target, selector in
                self?.displayLink(target: target, selector: selector) ?? CADisplayLink()
            },
            tick: tick
        )
    }
}
#endif

// MARK: - MotionFrameLink

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
public final class MotionFrameLink<Value>: AnimationDriver {

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
        get { !isStopped && !(frameLink?.isPaused ?? true) }
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

    private var frameLink: FrameLink?
    private let frameLinkFactory: (@escaping (_ timestamp: CFTimeInterval, _ targetTimestamp: CFTimeInterval) -> Void) -> any FrameLink
    private var isStopped = true
    private var lastRenderTimestamp: CFTimeInterval = 0
    private var animationStartTime: CFTimeInterval = 0
    private var progressTween = Tween(0.0, 1.0)
    private var completions: [() -> Void] = []

    /// Creates a motion frame link driven by the given source.
    ///
    /// ```swift
    /// let link = MotionFrameLink(for: myView, 0.0, { value in
    ///     myView.alpha = CGFloat(value)
    /// }) {
    ///     To(1.0).duration(0.3)
    /// }
    /// ```
    public init(
        for source: some FrameLinkSource,
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) {
        self.apply = apply
        self.initialValue = initialValue
        self.motion = motion()
        self.frameLinkFactory = { tick in
            source.makeFrameLink(tick: tick)
        }
        source.links[ObjectIdentifier(self)] = self
    }

    deinit {
        nonisolated(unsafe) let link = frameLink
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                link?.invalidate()
            }
        } else {
            DispatchQueue.main.async { @MainActor in
                link?.invalidate()
            }
        }
    }

    /// Plays the animation from a specified progress value to another.
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
            ensureFrameLink().activate()
        }
        ensureFrameLink().isPaused = false
    }

    /// Reverses the animation direction.
    /// - Parameter from: The starting progress value (defaults to current progress if nil)
    public func reverse(from: Double? = nil) {
        play(
            from: from,
            to: progressTween.end > progressTween.start && _progress != 0.0 || _progress == 1.0 ? 0.0 : 1.0
        )
    }

    /// Toggles the animation state between playing and paused.
    public func toggle() {
        if (frameLink?.isPaused ?? true) || isStopped {
            play()
        } else {
            pause()
        }
    }

    /// Sets the animation directly to a specific progress value without animating.
    /// - Parameter progress: The progress value to set (between 0.0 and 1.0)
    public func set(progress: Double) {
        _progress = progress
        apply(prepareIfNeeded().lerp(initialValue, progress))
    }

    /// Pauses the animation at the current progress.
    public func pause() {
        frameLink?.isPaused = true
    }

    /// Stops the animation and resets to a specific progress value.
    /// - Parameter progress: The progress value to stop at (defaults to 0.0)
    public func stop(at progress: Double = 0) {
        frameLink?.invalidate()
        frameLink = nil
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

    private func ensureFrameLink() -> any FrameLink {
        if let frameLink { return frameLink }
        let link = frameLinkFactory { [weak self] timestamp, targetTimestamp in
            self?.tick(timestamp: timestamp, targetTimestamp: targetTimestamp)
        }
        frameLink = link
        return link
    }

    private func tick(timestamp: CFTimeInterval, targetTimestamp: CFTimeInterval) {
        guard lastRenderTimestamp != 0 else {
            animationStartTime = timestamp
            lastRenderTimestamp = timestamp
            set(progress: progressTween.start)
            return
        }
        let data = prepareIfNeeded()

        let duration = data.duration?.seconds ?? .defaultAnimationDuration

        let elapsed = targetTimestamp - animationStartTime
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
            lastRenderTimestamp = timestamp
        }
    }

    private func notifyCompletions() {
        completions.forEach { $0() }
        completions.removeAll()
    }
}

// MARK: - Convenience initializers

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension MotionFrameLink where Value == Double {

    /// Creates a motion frame link for `Double` values driven by the given source.
    ///
    /// ```swift
    /// let link = MotionFrameLink(for: myView) { value in
    ///     myView.alpha = CGFloat(value)
    /// }
    /// ```
    public convenience init(
        for source: some FrameLinkSource,
        _ apply: @escaping (Value) -> Void
    ) {
        self.init(for: source, 0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }
}

// MARK: - Source extensions

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
extension FrameLinkSource {

    /// Creates a motion frame link driven by this source.
    ///
    /// ```swift
    /// let link = myView.motionFrameLink(0.0, { value in
    ///     myView.alpha = CGFloat(value)
    /// }) {
    ///     To(1.0).duration(0.3)
    /// }
    /// ```
    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionFrameLink<Value>(
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> MotionFrameLink<Value> {
        let link = MotionFrameLink(for: self, initialValue, apply, motion: motion)
        links[ObjectIdentifier(link)] = link
        return link
    }

    /// Creates a motion frame link for `Double` values driven by this source.
    ///
    /// ```swift
    /// let link = myView.motionFrameLink { progress in
    ///     myView.alpha = CGFloat(progress)
    /// }
    /// ```
    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func motionFrameLink(
        _ apply: @escaping (Double) -> Void
    ) -> MotionFrameLink<Double> {
        motionFrameLink(0, apply) {
            Lerp {
                $0.interpolated(towards: 1, amount: $1)
            }
        }
    }
}

// MARK: - Lifecycle management

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension NSObject {

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
    public func removeMotion<Value>(_ motion: MotionFrameLink<Value>) {
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

// MARK: - Deprecated aliases

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@available(*, deprecated, renamed: "MotionFrameLink")
public typealias MotionDisplayLink<Value> = MotionFrameLink<Value>

@available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 6.0, *)
@MainActor
extension FrameLinkSource {

    @available(*, deprecated, renamed: "motionFrameLink(_:_:motion:)")
    public func motionDisplayLink<Value>(
        _ initialValue: Value,
        _ apply: @escaping (Value) -> Void,
        @MotionBuilder<Value> motion: () -> AnyMotion<Value>
    ) -> MotionFrameLink<Value> {
        motionFrameLink(initialValue, apply, motion: motion)
    }

    @available(*, deprecated, renamed: "motionFrameLink(_:)")
    public func motionDisplayLink(
        _ apply: @escaping (Double) -> Void
    ) -> MotionFrameLink<Double> {
        motionFrameLink(apply)
    }
}
