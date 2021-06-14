//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit

public struct VDTransitionContext {
	public let fromVC: UIViewController
	public let toVC: UIViewController
	public let type: TransitionType
	public let container: UIView
	public var topVC: UIViewController {
		type.show ? toVC : fromVC
	}
	public var bottomVC: UIViewController {
		type.show ? fromVC : toVC
	}
	public var fromView: UIView { fromVC.view }
	public var toView: UIView { toVC.view }
	public var topView: UIView { topVC.view }
	public var bottomView: UIView { bottomVC.view }
}
