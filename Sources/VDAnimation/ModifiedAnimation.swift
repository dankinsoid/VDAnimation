import Foundation
import VDChain

public struct ModifiedAnimation: VDAnimationProtocol, Chainable {
    
	var options: AnimationOptions
	let animation: VDAnimationProtocol
    
	public func delegate(with options: AnimationOptions) -> AnimationDelegateProtocol {
		animation.delegate(with: options.or(self.options))
	}
}
