//
//  SwipeView.swift
//  VDTransition
//
//  Created by Данил Войдилов on 14.04.2021.
//

import UIKit
import ConstraintsOperators

final class SwipeView: UIScrollView, UIScrollViewDelegate {
	
	private let content = UIView()
	
	var instances: [Instance.Key: Instance] = [:]
	var edges: UIRectEdge {
		instances.reduce([]) { $0.union($1.key.edge) }
	}
	var initialOffset: CGPoint {
		CGPoint(
			x: edges.contains(.right) ? frame.width : 0,
			y: edges.contains(.bottom) ? frame.height : 0
		)
	}
	
	subscript(_ key: Instance.Key) -> Instance {
		if let result = instances[key] {
			return result
		}
		let result = Instance(scroll: self, key: key)
		instances[key] = result
		reset()
		return result
	}
	
	init() {
		super.init(frame: .zero)
		afterInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	private func afterInit() {
		alpha = 0
		isPagingEnabled = true
		contentInsetAdjustmentBehavior = .never
		isUserInteractionEnabled = false
		isDirectionalLockEnabled = true
		
		addSubview(content)
		content.frame.size = CGSize(width: frame.width * 2, height: frame.height)
		content.ignoreAutoresizingMask()
		content.edges() =| self
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		instances.forEach { $0.value.didScroll() }
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		instances.forEach { $0.value.didEndDecelerating() }
		reset()
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		guard Set(instances.map { $0.key.edge }).count == 1 else { return }
		(instances.first(where: { $0.key.startFromEdges }) ?? instances.first)?.value.willBeginDragging()
	}
	
	func reset() {
		delegate = nil
		alwaysBounceVertical = edges.contains(.top) || edges.contains(.bottom)
		alwaysBounceHorizontal = edges.contains(.right) || edges.contains(.left)
		let k = CGSize(
			width: edges.contains(.right) && edges.contains(.left) ? 3 : 2,
			height: edges.contains(.top) && edges.contains(.bottom) ? 3 : 2
		)
		content.width =| width * k.width
		content.height =| height * k.height
		content.frame.size = CGSize(width: frame.width * k.width, height: frame.height * k.height)
		contentOffset = initialOffset
		delegate = self
	}
	
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		instances.contains(where: { $0.value.shouldBegin(gestureRecognizer) })
			&& super.gestureRecognizerShouldBegin(gestureRecognizer)
	}
}

extension SwipeView {
	final class Instance {
		weak var driver: InteractiveDriver?
		
		let edges: UIRectEdge
		let startFromEdges: Bool
		private var wasBegan = false
		private var lastPercent: CGFloat?
		private let threshold: CGFloat = 36
		var observers: [(CGFloat) -> Void] = []
		unowned var scroll: SwipeView
		
		private var percent: CGFloat {
			let dif = scroll.contentOffset - scroll.initialOffset
			if dif.x == 0 {
				return offset / scroll.frame.height
			} else {
				return offset / scroll.frame.width
			}
		}
		
		private var offset: CGFloat {
			var value: CGFloat
			let offset = scroll.contentOffset - scroll.initialOffset
			if offset.x == 0 {
				guard edges.contains(.top) || edges.contains(.bottom) else { return 0 }
				value = offset.y
				if edges.contains(.bottom) && edges.contains(.top) {
					value = abs(value)
				} else if edges.contains(.bottom) {
					value = -value
				}
				return value
			} else {
				guard edges.contains(.left) || edges.contains(.right) else { return 0 }
				value = offset.x
				if edges.contains(.right) && edges.contains(.left) {
					value = abs(value)
				} else if edges.contains(.right) {
					value = -value
				}
				return value
			}
		}
		
		init(scroll: SwipeView, key: Key) {
			self.scroll = scroll
			self.edges = key.edge
			self.startFromEdges = key.startFromEdges
		}
		
		func didScroll() {
			guard scroll.frame.width > 0 else { return }
			let percent = max(0, min(1, self.percent))
			if driver?.wasBegun == false, percent > 0 {
				scroll.instances.filter({ $0.value.driver?.wasBegun == true }).forEach {
					$0.value.driver?.cancel()
				}
				driver?.begin()
			}
			guard driver?.wasBegun == true else { return }
			defer { notify() }
			guard percent != lastPercent else { return }
			lastPercent = percent
			driver?.update(percent)
		}
		
		func didEndDecelerating() {
			guard driver?.wasBegun == true else { return }
			let percent = self.percent
			lastPercent = percent
			if percent >= 1 {
				driver?.finish()
				lastPercent = nil
			} else if percent <= 0 {
				driver?.cancel()
				lastPercent = nil
			}
		}
		
		func willBeginDragging() {
			guard driver?.wasBegun == false else { return }
			driver?.begin()
		}
		
		func shouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
			guard startFromEdges else {
				return true
			}
			let size = gestureRecognizer.view?.frame.size ?? scroll.frame.size
			let location = gestureRecognizer.location(in: gestureRecognizer.view ?? scroll)
			
			let edgeInsets = UIEdgeInsets(
				top: abs(location.y),
				left: abs(location.x),
				bottom: abs(size.height - location.y),
				right: abs(size.width - location.x)
			)
			
			return (
				edges.contains(.right) && edgeInsets.left < threshold ||
				edges.contains(.left) && edgeInsets.right < threshold ||
				edges.contains(.top) && edgeInsets.bottom < threshold ||
				edges.contains(.bottom) && edgeInsets.top < threshold
			)
		}
		
		private func notify() {
			guard !observers.isEmpty else { return }
			let offset = self.offset
			observers.forEach {
				$0(offset)
			}
		}
		
		struct Key: Hashable {
			let edge: UIRectEdge
			let startFromEdges: Bool
		}
	}
}

extension UIRectEdge: Hashable {
	var inverted: UIRectEdge {
		var result: UIRectEdge = []
		if contains(.left) { result.insert(.right) }
		if contains(.right) { result.insert(.left) }
		if contains(.top) { result.insert(.bottom) }
		if contains(.bottom) { result.insert(.top) }
		return result
	}
}
