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
        
        animator = Sequential {
            circle.ca.backgroundColor.set(.systemBlue).duration(1)
            circle.ca.backgroundColor.set(.systemRed).duration(1)
            circle.ca.backgroundColor.set(.systemGreen).duration(1)
        }
        animator?.start()
    }

    @IBAction func slide(_ sender: UISlider) {
//        circle.backgroundColor = .systemBlue
        animator?.progress = Double(sender.value)
    }
    
}
