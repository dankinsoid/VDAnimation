//
//  Bases.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit
import VDKit

public protocol UIKitPropertySettable: AnyObject {}

extension UIKitPropertySettable {
    public var ca: ChainingProperty<UIKitChainingAnimation<Self>, Self> {
			ChainingProperty(UIKitChainingAnimation(self, setInitial: { $0 }), getter: \.self)
    }
}

extension UIView: UIKitPropertySettable {}
extension CALayer: UIKitPropertySettable {}

//extension NSLayoutConstraint: UIKitPropertySettable {
//    public var ca: AnimatedPropertyMaker<NSLayoutConstraint> {
//        return AnimatedPropertyMaker(object: { self })
//    }
//}

extension NSLayoutConstraint {

    func didUpdate() {
        guard isActive else { return }
        let view1 = firstItem as? UIView ?? (firstItem as? UILayoutGuide)?.owningView
        let view2 = secondItem as? UIView ?? (secondItem as? UILayoutGuide)?.owningView
        if let parent = view1?.commonSuper(with: view2) {
            parent.layoutIfNeeded()
        } else {
            (view1?.superview ?? view1)?.layoutIfNeeded()
            guard view1 !== view2 else { return }
            (view2?.superview ?? view2)?.layoutIfNeeded()
        }
    }

}

extension UIView {
    
    fileprivate func commonSuper(with: UIView?) -> UIView? {
        guard let view = with else { return nil }
        if isDescendant(of: view) { return view.superview ?? view }
        return commonParent(with: view)
    }
    
    private func commonParent(with view: UIView) -> UIView? {
        if view.isDescendant(of: self) { return superview ?? self }
        return superview?.commonParent(with: view)
    }
    
}
