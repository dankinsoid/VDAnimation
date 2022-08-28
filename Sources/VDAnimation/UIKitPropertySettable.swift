import UIKit
import VDChain

public protocol UIKitPropertySettable: AnyObject {}

extension UIKitPropertySettable {
    
    public var ca: Chain<EmptyAnimationChaining<Self>> {
        EmptyAnimationChaining(self).wrap()
    }
}

extension UIView: UIKitPropertySettable {}
extension CALayer: UIKitPropertySettable {}
