//
//  Foundation++.swift
//  CA
//
//  Created by crypto_user on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

extension Sequence {
    
    func reduce<Result>(while condition: (Result) -> Bool, _ initialValue: Result, _ reducing: (Result, Element) -> Result) -> Result {
        var result = initialValue
        for element in self {
            guard condition(result) else { return result }
            result = reducing(result, element)
        }
        return result
    }
    
}
