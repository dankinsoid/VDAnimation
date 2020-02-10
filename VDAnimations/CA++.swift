//
//  CA++.swift
//  CA
//
//  Created by Daniil on 10.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension CALayer {
    
    func allSublayers() -> [CALayer] {
        (sublayers ?? []) + (sublayers?.reduce([], { $0 + $1.allSublayers() }) ?? [])
    }
    
    func allProperties() -> [String: Any] {
        Dictionary(uniqueKeysWithValues: CALayer.allKeys.map { ($0, value(forKey: $0)) })
    }
    
    static var allKeys: [String] = {
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(CALayer.self, &count) else { return [] }
        var rv: [String] = []
        for i in 0..<Int(count) {
            let property = properties[i]
            let name = String(utf8String: property_getName(property)) ?? ""
            rv.append(name)
        }
        free(properties)
        return rv
    }()
    
    func allPropertyNames() -> [String] {
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(type(of: self), &count) else { return [] }
        var rv: [String] = []
        for i in 0..<Int(count) {
            let property = properties[i]
            let name = String(utf8String: property_getName(property)) ?? ""
            rv.append(name)
        }
        free(properties)
        return rv
    }
    
    static func ff(_ action: () -> ()) {
        guard let window = UIApplication.shared.keyWindow else { return }
        let all = [window.layer] + window.layer.allSublayers()
        print(all.count)
        let before = Dictionary(uniqueKeysWithValues: all.map { ($0, $0.allProperties()) })
        action()
        let after = Dictionary(uniqueKeysWithValues: all.map { ($0, $0.allProperties()) })
        before.forEach {
            let (layer, dict) = $0
            guard let new = after[layer] else { return }
            dict.forEach {
                print($0.key)
                print($0.value as? CGRect)
                print($0.value as? CGFloat)
                print($0.value as? CGSize)
                let cg = $0.value as! CGColor
                if cg.components?.isEmpty == false {
                    print(cg.components!)
                    print(UIColor(cgColor: cg))
                }
                print()
            }
        }
    }
}

class MyAnimation: CAAction {
    
    func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
        
    }
    
}


//public static var layoutSubviews: UIView.AnimationOptions { get }
//
//public static var allowUserInteraction: UIView.AnimationOptions { get } // turn on user interaction while animating
//
//public static var beginFromCurrentState: UIView.AnimationOptions { get } // start all views from current value, not initial value
//
//public static var `repeat`: UIView.AnimationOptions { get } // repeat animation indefinitely
//
//public static var autoreverse: UIView.AnimationOptions { get } // if repeat, run animation back and forth
//
//public static var overrideInheritedDuration: UIView.AnimationOptions { get } // ignore nested duration
//
//public static var overrideInheritedCurve: UIView.AnimationOptions { get } // ignore nested curve
//
//public static var allowAnimatedContent: UIView.AnimationOptions { get } // animate contents (applies to transitions only)
//
//public static var showHideTransitionViews: UIView.AnimationOptions { get } // flip to/from hidden state instead of adding/removing
//
//public static var overrideInheritedOptions: UIView.AnimationOptions { get } // do not inherit any options or animation type
//
//
//public static var curveEaseInOut: UIView.AnimationOptions { get } // default
//
//public static var curveEaseIn: UIView.AnimationOptions { get }
//
//public static var curveEaseOut: UIView.AnimationOptions { get }
//
//public static var curveLinear: UIView.AnimationOptions { get }
//
//
//public static var transitionFlipFromLeft: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromRight: UIView.AnimationOptions { get }
//
//public static var transitionCurlUp: UIView.AnimationOptions { get }
//
//public static var transitionCurlDown: UIView.AnimationOptions { get }
//
//public static var transitionCrossDissolve: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromTop: UIView.AnimationOptions { get }
//
//public static var transitionFlipFromBottom: UIView.AnimationOptions { get }
//
//
//public static var preferredFramesPerSecond60: UIView.AnimationOptions { get }
//
//public static var preferredFramesPerSecond30: UIView.AnimationOptions { get }
