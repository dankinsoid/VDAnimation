import Foundation

public struct Parallel: VDAnimationProtocol {
    
	private let animations: [VDAnimationProtocol]
	
	public init(_ animations: [VDAnimationProtocol]) {
		self.animations = animations
	}
	
	public init(_ animations: VDAnimationProtocol...) {
		self = .init(animations)
	}
	
	public init(@AnimationsBuilder _ animations: () -> [VDAnimationProtocol]) {
		self = .init(animations())
	}
	
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		if animations.count == 1 {
			return animations[0].delegate(with: options)
		} else if animations.isEmpty {
			return EmptyAnimationDelegate()
		} else {
			return Delegate(animations: animations.map { $0.delegate(with: .empty) }, options: options)
		}
	}
	
	final class Delegate: AnimationDelegateProtocol {
		var isRunning: Bool { animations.contains(where: { $0.isRunning }) }
		var position: AnimationPosition {
			get { getPosition() }
			set {
				set(position: newValue, needStop: false)
			}
		}
		var isInstant: Bool { !animations.contains(where: { !$0.isInstant }) }
		private let animations: [Delay]
		private var completions: [(Bool) -> Void] = []
		private let maxDuration: AnimationDuration?
		var options: AnimationOptions
		private var progresses: [ClosedRange<Double>] = []
		private var allOptions: [AnimationOptions] = []
		private let initOptions: [AnimationOptions]
		private var prevProgress: Double = 0
		private var wasStopped = false
		private var stopped = 0
		private var completedCount = 0
		
		init(animations: [AnimationDelegateProtocol], options: AnimationOptions) {
			self.maxDuration = Delegate.maxDuration(for: animations)
			self.animations = animations.map { Delay($0) }
			self.options = options.or(AnimationOptions(duration: maxDuration))
			initOptions = animations.map { $0.options }
			prepare()
		}
		
		private func prepare() {
			updateOptions()
			animations.forEach {
				$0.add {[weak self] in
					self?.completed(completed: $0)
				}
			}
		}
		
		private func completed(completed: Bool) {
			guard !wasStopped else {
				stopped += 1
				if stopped == animations.count {
					stopped = 0
					completions.forEach { $0(completed) }
				}
				return
			}
			completedCount += 1
			let finished = completedCount >= animations.count
			if finished || !completed {
				if options.complete != false {
					wasStopped = true
					animations.forEach {
						$0.stop(at: .current)
					}
				} else {
					completions.forEach { $0(completed) }
				}
			}
		}
		
		func play(with options: AnimationOptions) {
			if options != .empty {
				self.options = options.or(self.options)
				updateOptions()
			}
			guard !isRunning else { return }
			start()
		}
		
		func pause() {
			animations.forEach {
				$0.pause()
			}
		}
		
		func stop(at position: AnimationPosition?) {
			wasStopped = true
			if let position = position {
				set(position: position, needStop: true)
			} else {
				animations.forEach {
					$0.stop(at: .current)
				}
			}
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			completions.append(completion)
		}
		
		private func updateOptions() {
			progresses = getProgresses()
			allOptions = setDuration()
		}
		
		private func complete(_ completed: Bool) {
			completions.forEach {
				$0(completed)
			}
		}
		
		func start() {
			guard animations.count > 1 else {
				return animations[0].play()
			}
			let full = options.duration?.absolute ?? maxDuration?.absolute ?? 0
			zip(animations, allOptions).forEach { arg in
				if options.isReversed == true {
					let delay = full - (arg.1.duration?.absolute ?? 0)
					arg.0.play(with: arg.1, delay: delay)
				} else {
					arg.0.play(with: arg.1, delay: 0)
				}
			}
		}
		
		func set(position: AnimationPosition, needStop stop: Bool) {
			switch position {
			case .start:
				animations.forEach { $0.set(position: .start, stop: stop) }
				prevProgress = 0
				completedCount = 0
			case .end:
				animations.forEach { $0.set(position: .end, stop: stop) }
				prevProgress = 1
				completedCount = animations.count
            default:
				guard !animations.isEmpty else { return }
                let k = position.complete
				completedCount = 0
				for i in 0..<progresses.count {
					if progresses[i].upperBound <= k || progresses[i].upperBound == 0 {
						guard progresses[i].upperBound > prevProgress else { continue }
						animations[i].set(position: .end, stop: stop)
						completedCount += 1
					} else if progresses[i].lowerBound >= k {
						guard progresses[i].lowerBound < prevProgress else { continue }
						animations[i].set(position: .start, stop: stop)
					} else {
						animations[i].set(position: .progress(k / progresses[i].upperBound), stop: stop)
					}
				}
				prevProgress = k
			}
		}
		
		private func getPosition() -> AnimationPosition {
			guard !animations.isEmpty else { return .end }
			if let i = progresses.firstIndex(of: 0...1) {
				return animations[i].position
			}
			let i = animations.firstIndex(where: { $0.isRunning }) ?? 0
			return .progress((progresses[i].upperBound - progresses[i].lowerBound) * animations[i].position.complete)
		}
		
		private func setDuration() -> [AnimationOptions] {
			guard !animations.isEmpty else { return [] }
			let full = options.duration?.absolute ?? maxDuration?.absolute ?? 0
			let maxDuration = self.maxDuration?.absolute ?? 0
			let k = maxDuration == 0 ? 1 : full / maxDuration
			let childrenDurations: [Double] = initOptions.map {
				guard let setted = $0.duration else {
					return full
				}
				switch setted {
				case .absolute(let time):   return time * k
				case .relative(let r):      return full * min(1, r)
				}
			}
			var result = childrenDurations.map({ options.set([.duration(.absolute($0)), .complete(false)]) })
			setCurve(&result, duration: full)
			return result
		}
		
		private static func maxDuration(for array: [AnimationDelegateProtocol]) -> AnimationDuration? {
			guard array.contains(where: {
				$0.options.duration?.absolute != nil && !$0.isInstant
			}) else { return nil }
			let maxDuration = array.reduce(0, { max($0, $1.options.duration?.absolute ?? 0) })
			return .absolute(maxDuration)
		}
		
		private func setCurve(_ array: inout [AnimationOptions], duration: Double) {
			guard let fullCurve = options.curve, fullCurve != .linear else {
				return
			}
			for i in 0..<animations.count {
				var (curve1, newDuration) = fullCurve.split(range: progresses[i])
				if let curve2 = animations[i].options.curve {
					curve1 = BezierCurve.between(curve1, curve2)
				}
				array[i].duration = .absolute(duration * newDuration)
				array[i].curve = curve1
			}
		}
		
		private func getProgresses() -> [ClosedRange<Double>] {
			guard !animations.isEmpty else { return [] }
			let array = initOptions
			let duration = options.duration?.absolute ?? maxDuration?.absolute ?? 0
			guard duration > 0 else {
				return Array(repeating: 0...1, count: array.count)
			}
			var progresses: [ClosedRange<Double>] = []
			for anim in array {
				let end: Double
				if let relative = anim.duration?.relative {
					end = min(1, max(0, relative))
				} else {
					end = (anim.duration?.absolute ?? duration) / duration
				}
				progresses.append(0...end)
			}
			return progresses
		}
	}
	
	private final class Delay: AnimationDelegateProtocol {
		let animation: AnimationDelegateProtocol
		var isRunning: Bool { animation.isRunning || interval?.isRunning == true }
		var position: AnimationPosition {
			get { animation.position }
			set { animation.position = newValue }
		}
		var options: AnimationOptions { animation.options }
		var isInstant: Bool { animation.isInstant }
		var interval: Interval.Delegate?
		var delay: TimeInterval { interval?.duration ?? 0 }
		
		init(_ animation: AnimationDelegateProtocol) {
			self.animation = animation
		}
		
		func add(completion: @escaping (Bool) -> Void) {
			animation.add(completion: completion)
		}
		
		func play(with options: AnimationOptions) {
			play(with: options, delay: delay)
		}
		
		func play(with options: AnimationOptions, delay: TimeInterval) {
			if delay > 0 {
				if interval == nil {
					interval = Interval.Delegate(options: .empty)
					interval?.duration = delay
					interval?.add {[weak self] in
						if $0 {
							self?.animation.play(with: options)
						}
					}
				}
				if interval?.position == .end {
					animation.play(with: options)
				} else {
					interval?.play(with: AnimationOptions(duration: .absolute(delay)))
				}
			} else {
				interval?.stop(at: .current)
				interval = nil
				animation.play(with: options)
			}
		}
		
		func stop(at position: AnimationPosition?) {
			interval?.stop(at: .current)
			interval = nil
			animation.stop(at: position)
		}
		
		func pause() {
			interval?.pause()
			animation.pause()
		}
	}
}
