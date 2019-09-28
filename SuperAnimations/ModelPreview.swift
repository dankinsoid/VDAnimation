//
//  ModelPreview.swift
//  SuperAnimations
//
//  Created by Daniil on 28.09.2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import SwiftUI

struct AnimationView: View {
    var animate: AnimatorProtocol
    
    var body: some View {
        switch animate {
        case let an as Animate:
            return AnimateView(animate: an, showLine: true).asAny
        case let an as Interval:
            return AnimateView(animate: an, showLine: false).asAny
        case let an as Sequential:
            return HStack(alignment: .center, spacing: 0) {
                ForEach(an.animations.enumerated().map({ $0.offset }), id: \.self) {
                    AnimationView(animate: an.animations[$0])
                }
            }.asAny
            case let an as Parallel:
                return
                    VStack(alignment: .leading, spacing: 0) {
                    ForEach(an.animations.enumerated().map({ $0.offset }), id: \.self) { i in
                            AnimationView(animate: an.animations[i])
                        }
                    
                }.asAny
        default:
            return EmptyView().asAny
        }
    }
}


struct AnimateView: View {
    
    var animate: AnimatorProtocol
    let showLine: Bool
    
    var body: some View {
        ZStack(alignment: .center) {
            if showLine {
            Color(hue: .random(in: 0...1), saturation: 0.7, brightness: 0.9)
                HStack(alignment: .center, spacing: 2) {
                    Text("\(Decimal(animate.timing.duration).description)".prefix(4))
                    .foregroundColor(.white)

            BezierView(bezier: animate.timing.curve)
                .scale(x: 1, y: -1, anchor: .center)
                .stroke(lineWidth: 1.5)
                .foregroundColor(.white)
                .aspectRatio(contentMode: .fit)
                .layoutPriority(1)
                .padding(.all, 8)
                }
            } else {
                ZStack {
                Text("\(Decimal(animate.timing.duration).description)".prefix(4))
                    .foregroundColor(.blue)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1.5)
                    .padding(1.5)
                }
            }
        }
        .cornerRadius(8)
        .frame(
            width: CGFloat(self.animate.timing.duration) * 300,
            height: 60,
            alignment: .leading
        )
    }
}


struct ModelPreview_Previews: PreviewProvider {
    
    static var animation: AnimatorProtocol {
        Parallel {
            Sequential {
                Animate {}
                Animate {}
            }
                .duration(0.8)
                .curve(.easeInOut)
            Sequential {
                Animate {}
                    .curve(.ease)
                Interval(0.1)
                Parallel {
                    Animate {}
                        .duration(0.4)
                        .curve(.easeInOut)
                    Sequential {
                        Animate {}
                            .curve(.easeIn)
                            .duration(0.2)
                        Animate {}
                            .curve(.easeOut)
                            .duration(0.2)
                            .delay(0.1)
                    }
                }
            }
        }
    }
    
    static var previews: some View {
        AnimationView(animate: animation)
            .previewLayout(.sizeThatFits)
    }
    
}

extension Text {
    func color(_ color: Color?) -> Text {
        foregroundColor(color)
    }
}

extension View {
    var asAny: AnyView { AnyView(self) }
}

struct BezierView: Shape {
    
    let bezier: BezierCurve
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: rect.width, y: rect.height), control1: bezier.point1 * rect.size, control2: bezier.point2 * rect.size)
        }
    }
    
}
