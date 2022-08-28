import UIKit

extension CGSize {
    
	public subscript(_ axe: NSLayoutConstraint.Axis) -> CGFloat {
		switch axe {
		case .horizontal:   return width
		default:            return height
		}
	}
}
