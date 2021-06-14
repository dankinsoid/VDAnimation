//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit

extension CGSize {
	public subscript(_ axe: NSLayoutConstraint.Axis) -> CGFloat {
		switch axe {
		case .horizontal:   return width
		default:            return height
		}
	}
}
