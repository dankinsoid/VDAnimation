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
    public var ca: ChainProperty<UIKitChainingAnimation<Self>, Self> {
			ChainProperty(UIKitChainingAnimation(self, setInitial: { $0 }), getter: \.self)
    }
}

extension UIView: UIKitPropertySettable {}
extension CALayer: UIKitPropertySettable {}
