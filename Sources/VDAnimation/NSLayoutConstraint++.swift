//
//  NSLayoutConstraint++.swift
//  CA
//
//  Created by crypto_user on 13.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import UIKit

public final class ConstraintsOwner {
    let constraints: [NSLayoutConstraint]
    
    init(_ constraints: [NSLayoutConstraint]) {
        self.constraints = constraints
    }
}
