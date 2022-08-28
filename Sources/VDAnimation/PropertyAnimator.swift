import UIKit
import VDChain

public protocol AnimationChaining: ConsistentChaining where Root: AnyObject {
    
    var root: Root? { get }
}

@dynamicMemberLookup
public struct EmptyAnimationChaining<Root: AnyObject>: AnimationChaining {
    
    public weak var root: Root?
	
	public init(_ root: Root?) {
		self.root = root
	}
	
	public subscript<A>(dynamicMember keyPath: KeyPath<Root, A>) -> PropertyChain<Self, A> {
        PropertyChain<Self, A>(self, getter: keyPath)
	}
	
    
    public func apply(on root: inout Root) {
    }
    
    public func getAllValues(for root: Root) -> Void {
        ()
    }
    
    public func applyAllValues(_ values: Void, for root: inout Root) {
    }
}

extension KeyPathChain: AnimationChaining where Base: AnimationChaining {
    
    public var root: Base.Root? {
        base.root
    }
}

extension ChainedChain: AnimationChaining where Base: AnimationChaining {
    
    public var root: Base.Root? {
        base.root
    }
}

extension Chain: VDAnimationProtocol where Base: AnimationChaining {
    
    public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
        var cached: Base.AllValues?
        return ChainingAnimationDelegete(
            apply: { [base] in
                guard var root = base.root else { return }
                base.apply(on: &root)
            },
            setInitial: { [base] in
                guard var root = base.root else { return }
                let vaules = cached ?? base.getAllValues(for: root)
                cached = vaules
                base.applyAllValues(vaules, for: &root)
            },
            options: options
        )
    }
}

private final class ChainingAnimationDelegete: AnimationDelegateProtocol {
    
	var isRunning: Bool { inner.isRunning }
	var position: AnimationPosition {
		get { inner.position }
		set { set(position: newValue) }
	}
	var options: AnimationOptions { inner.options }
	var isInstant: Bool { inner.isInstant }
    let setInitial: () -> Void
    private var wasInited = false
	private var inner: AnimationDelegateProtocol
	
	init(apply: @escaping () -> Void, setInitial: @escaping () -> Void, options: AnimationOptions) {
		self.setInitial = setInitial
		self.inner = UIViewAnimate(apply).delegate(with: options)
	}
	
	func play(with options: AnimationOptions) {
		setInitialIfNeeded()
		inner.play(with: options)
	}
	
	func pause() {
		inner.pause()
	}
	
	func stop(at position: AnimationPosition?) {
		inner.stop(at: position)
	}
	
	public func set(position: AnimationPosition) {
		setInitialIfNeeded()
		inner.position = position
	}
	
	func add(completion: @escaping (Bool) -> Void) {
		inner.add(completion: completion)
	}
	
	private func setInitialIfNeeded() {
		guard !wasInited else { return }
		wasInited = true
		setInitial()
	}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension PropertyChain where Base: AnimationChaining {
	
	public func callAsFunction(_ gradient: Gradient<Value>) -> Chain<ChainedChain<Base, Value>> {
        ChainedChain(
            base: chaining,
            value: gradient.to
        ) { _ in
            gradient.from
        } set: { [getter] value, root in
            guard let writable = getter as? WritableKeyPath<Base.Root, Value> else { return }
            root[keyPath: writable] = value
        }
        .wrap()
	}
}
