//
//  ViewController.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController, CAAnimationDelegate {

    @IBOutlet weak var circle: UIView!
    let triangle = UIView()
    var animator: AnimatorProtocol?
    var anim = VDViewAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        circle.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animator =
        Sequential {
            circle.ca.backgroundColor.set(.black).withoutAnimation()
            circle.ca.backgroundColor.set(.systemBlue).relativeDuration(0.5)
            circle.ca.backgroundColor.set(.systemRed)
            circle.ca.backgroundColor.set(.systemGreen)
        }
        .duration(0.3)
        
        let date = Date()
        animator?.start { _ in
            print(Date().timeIntervalSince(date))
        }
    }

    @IBAction func slide(_ sender: UISlider) {
//        circle.backgroundColor = .systemBlue
        animator?.progress = Double(sender.value)
    }
    
}
