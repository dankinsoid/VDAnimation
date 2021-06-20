//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit
import VDKit

extension UIView {
	
	@discardableResult
	func edge(_ edge: Edges, to view: UIView, offset: CGFloat = 0, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		let result: NSLayoutConstraint
		switch edge {
		case .top:			result = topAnchor.constraint(equalTo: view.topAnchor, constant: offset)
		case .leading:	result = leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset)
		case .bottom:		result = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset)
		case .trailing: result = trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset)
		}
		result.priority = priority
		result.isActive = true
		return result
	}
}
