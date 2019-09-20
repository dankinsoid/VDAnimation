//
//  ViewController.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var circle: UIView!
    let triangle = UIView()
    var animator: AnimatorProtocol = Interval(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewPropertyAnimator()
        
        animator = Sequential {
            self.circle.ca.transform.set(CGAffineTransform(rotationAngle: .pi))
            self.circle.ca.backgroundColor.set(.systemGreen)
            self.circle.ca.backgroundColor.set(.systemRed)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animator.start {
            print($0 == .end)
        }
    }

    @IBAction func slide(_ sender: UISlider) {
        animator.progress = Double(sender.value)
    }
    
}
