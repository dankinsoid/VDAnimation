//
//  ViewController.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let circle = UIView()
    let triangle = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Parallel {
            Sequential {
                circle.ca.frame.size.width.set(circle.frame.width * 1).duration(0.2)
                circle.ca.frame.size.width.set(circle.frame.width * 1.2).duration(0.1)
                circle.ca.frame.size.width.set(circle.frame.width * 0.3)
                Parallel {
                    view.ca.backgroundColor.set(.clear)
                    Sequential {
                        Animator { self.view.bounds = .zero }.duration(0.1)
                        Interval(0)
                        view.ca.backgroundColor.set(.white)
                    }
                }
            }
            .duration(1)
            Sequential {
                circle.ca.backgroundColor.set(.white)
                circle.ca.backgroundColor.set(.blue)
            }
            Sequential {
                triangle.ca.frame.size.width.set(triangle.frame.width * 0.3)
                Interval(0.3)
                triangle.ca.frame.size.width.set(triangle.frame.width * 1)
            }
            .duration(0.5)
        }
        
    }

}
