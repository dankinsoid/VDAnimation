//
//  Refactor.swift
//  SuperAnimations
//
//  Created by Daniil on 15.10.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation

описание анимации, заданное снаружи

рассчет всех внутренних параметров

установка параметров

запуск анимации

public protocol AnimationBuilder {
    var description: SettedTiming { get set }
    func calculate() -> Animate.Timing
    func set(parameters: AnimationParameters)
}

public protocol AnimationProtocol {
    
    var description: SettedTiming { get set }
    func calculate() -> Animate.Timing
    func set(parameters: AnimationParameters)
    func _startnimation(_ completion: @escaping () -> ())
    
}

exte
