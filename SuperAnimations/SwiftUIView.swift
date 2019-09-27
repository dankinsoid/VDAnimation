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
    @State var color: Color = .red
    
    var animation1: AnimatorProtocol {
        Parallel {
            self.ca.scale.set(2.4 - self.scale)
            self.ca.color.set(.blue)
        }
    }
    
    @State var scale1: Double = 0
    
    var body: some View {
        print(scale)
        return HStack {
            Spacer().frame(width: CGFloat(40), height: nil, alignment: .center)
            VStack {
                Spacer()
                Button.init(action: {
                    self.animation1.start()
                }) {
                    ZStack {
                        Color.blue
                        Text("\(scale1)").foregroundColor(.white)
                    }
                }.frame(width: nil, height: 50, alignment: .center)
                Spacer()
                self.color
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
