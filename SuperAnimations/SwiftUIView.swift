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
    
    var body: some View {
        HStack {
            Spacer().frame(width: CGFloat(40), height: nil, alignment: .center)
            VStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        self.scale = 2.4 - self.scale
                    }
                }) {
                    ZStack {
                        Color.blue
                        Text("Press").foregroundColor(.white)
                    }
                }.frame(width: nil, height: 50, alignment: .center)
                Spacer()
                Color.red.aspectRatio(1, contentMode: .fill).scaleEffect(scale, anchor: .center).animation(.spring())
                Spacer()
            }
            Spacer().frame(width: CGFloat(40), height: nil, alignment: .center)
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
