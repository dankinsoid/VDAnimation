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
        Parallel {
            Sequential {
                Interval(1)
                circle.ca.transform.set(CGAffineTransform(scaleX: 1.3, y: 1.3))
                circle.ca.transform.set(CGAffineTransform(scaleX: 1.6, y: 1.6))
//                Interval()
//                circle.ca.backgroundColor.set(.systemRed).duration(relative: 0.5)
//                Animate {[weak self] in
//                    self?.circle.backgroundColor = .systemGreen
//                }
            }
            Sequential {
                circle.ca.backgroundColor.set(.systemRed).duration(relative: 0.5)
            }
        }
        .curve(.easeInOut)
        .duration(2)
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
