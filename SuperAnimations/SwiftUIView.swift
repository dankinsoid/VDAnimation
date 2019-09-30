//
//  SwiftUIView.swift
//  SuperAnimations
//
//  Created by crypto_user on 24/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import SwiftUI

struct SwiftUIView: View {
    
    @State var scale: CGFloat = 1
    @State var point: CGRect = .zero
    @State var progress: Double = 0
    @State var size: CGSize = .zero
    @State var color: ColorData = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)

    var interact: ViewAnimator<SwiftUIView> {
        self.interactive { it in
            it.scale = 2.4 - it.scale
            it.color = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
        }
    }
//    var animation1: AnimatorProtocol {
//
//        self.animate { it in
//            it.point.size = .zero
//        }
//
//        return Parallel {
//        }
//    }
    
    @State var scale1: Double = 0
    
    var body: some View {
        return HStack {
            Spacer().frame(width: CGFloat(40), height: nil, alignment: .center)
            VStack {
                Spacer()
                Slider(value: $progress)
                Spacer()
                Button.init(action: {
                    self.animate(to: 0.5) { it in
                        it.scale = 2.4 - it.scale
                        it.color = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
                    }
//                    self.interact.change(to: self.progress)
                }) {
                    ZStack {
                        Color.blue
                        Text("\(scale1)").foregroundColor(.white)
                    }
                }.frame(width: nil, height: 50, alignment: .center)
                    .transition(.scale)
                Spacer()
                Color(self.color)
                    .aspectRatio(1, contentMode: .fill)
                    .scaleEffect(scale, anchor: .center)
                Spacer()
            }
            Spacer()
                .frame(width: CGFloat(40), height: nil, alignment: .center)
        }
    }
    
}

struct ModifiedView<T: View>: View {
    var view: T
    var properties: Properties
    
    var body: some View {
        view.frame(width: properties.frame.width, height: properties.frame.height, alignment: .center)
    }
    
}

extension View {
    func properties(_ value: Properties) -> ModifiedView<Self> {
        ModifiedView(view: self, properties: value)
    }
}

struct Properties {
    var frame: CGRect
    
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

struct ColorData: Animatable, _ExpressibleByColorLiteral {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get {
            AnimatablePair(AnimatablePair(red, green), AnimatablePair(blue, alpha))
        }
        set {
            red = newValue.first.first
            green = newValue.first.second
            blue = newValue.second.first
            alpha = newValue.second.second
        }
    }
    
    init(_colorLiteralRed red: Float, green: Float, blue: Float, alpha: Float) {
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
    
}

extension Color {
    
    init(_ data: ColorData) {
        self = Color(.sRGB, red: data.red, green: data.green, blue: data.blue, opacity: data.alpha)
    }
    
}
