//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit

public final class ViewTransitionConfig {
	public var id: String = UUID().uuidString
	public var modifier: VDTransition<UIView>?
	init() {}
}

public protocol ViewTransitable: UIView {}

extension ViewTransitable {
	
	public var transition: ViewTransitionConfig {
		if let result = objc_getAssociatedObject(self, &transitionKey) as? ViewTransitionConfig {//<Self> {
			return result
		}
		let result = ViewTransitionConfig()
		objc_setAssociatedObject(self, &transitionKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
	}
}

extension UIView: ViewTransitable {}

private var transitionKey = "transitionKey"
