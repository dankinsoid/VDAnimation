import Foundation

public protocol VDAnimationProtocol {
	
	func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol
}

extension VDAnimationProtocol {
    
	public func delegate() -> AnimationDelegateProtocol {
		delegate(with: .empty)
	}
}

extension VDAnimationProtocol {
    
	var modified: ModifiedAnimation { ModifiedAnimation(options: .empty, animation: self) }
	
	@discardableResult
	public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> Void) -> AnimationDelegateProtocol {
		let result = delegate(with: options)
		let owner = Owner<AnimationDelegateProtocol>()
		owner.delegate = result
		result.add {
			completion($0)
			owner.delegate = nil
		}
		result.play()
		return result
	}
	
	@discardableResult
	public func start(_ completion: @escaping (Bool) -> Void) -> AnimationDelegateProtocol {
		start(with: .empty, { completion($0) })
	}
	
	@discardableResult
	public func start(_ completion: (() -> Void)? = nil) -> AnimationDelegateProtocol {
		start(with: .empty, { _ in completion?() })
	}
}

//extension AnimationDelegateProtocol {
//
//	public func set<F: BinaryFloatingPoint>(_ progress: F) {
//		self.progress = Double(progress)
////		set(position: .progress(Double(progress)), for: .empty, execute: true)
//	}
//
//	public func set(position: AnimationPosition) {
//		set(position: position, for: .empty, execute: true)
//	}
//}

extension Optional: VDAnimationProtocol where Wrapped: VDAnimationProtocol {
    
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		self?.delegate(with: options) ?? EmptyAnimationDelegate()
	}
}

public final class EmptyAnimationDelegate: AnimationDelegateProtocol {
    
	public var isInstant: Bool { true }
	public var options: AnimationOptions {
		.init(duration: .absolute(0), complete: true)
	}
	public var isRunning: Bool { false }
	public var position: AnimationPosition = .start
	private var completions: [(Bool) -> Void] = []
	public var infinity = false
	
	public func play(with options: AnimationOptions) {
		stop(at: .end)
	}
	public func pause() {}
	public func stop(at position: AnimationPosition?) {
		self.position = position ?? .end
		guard !infinity else { return }
		completions.forEach {
			$0(position == .end)
		}
	}
	public func add(completion: @escaping (Bool) -> Void) {
		completions.append(completion)
	}
}

final class Owner<T> {
    
	var delegate: T?
}
