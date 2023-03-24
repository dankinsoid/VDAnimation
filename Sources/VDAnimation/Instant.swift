import SwiftUI

public struct Instant<Value>: AnimationType {
	
	private let block: () -> Value
	
	public init(_ closure: @escaping () -> Value) {
		block = closure
	}

    public func createDelegate() -> Delegate {
        Delegate(block)
    }
    
    public func duration(proposal: ProposedAnimationDuration) -> AnimationDuration {
        .absolute(0)
    }
    
    public func createOptions() -> Options {
        Options()
    }
	
    public final class Delegate: InteractiveAnimationDelegate {
        
        public typealias Result = Value
        
        public var isRunning: Bool {
            get { _isRunning }
            set {
                guard newValue != _isRunning, newValue else { return }
                act()
            }
        }
        public var position: AnimationPosition {
            get { _position }
            set {
                let oldValue = _position
                _position = newValue
                guard newValue == .end, newValue != oldValue else { return }
                act()
            }
        }
        let body: () -> Result
        private var _isRunning = false
        private var _position: AnimationPosition = .start
        
        
		private var completions: [(Bool) -> Void] = []
//		var isInstant: Bool { true }
        
		init(_ body: @escaping () -> Result) {
			self.body = body
		}
		
        public func stop(at position: UIViewAnimatingPosition) {
            guard position == .end, self._position != .end else { return }
            act()
        }
        
        public func start(with options: Options, _ completion: @escaping (Bool) -> Void) -> Result {
            let result = act()
            completion(true)
            return result
        }
        
        @discardableResult
        private func act() -> Result {
            _isRunning = true
            defer { _isRunning = false }
            _position = .end
            return body()
        }
        
        public struct Options {
        }
	}
}
