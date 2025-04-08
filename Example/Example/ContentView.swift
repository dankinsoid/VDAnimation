import SwiftUI
import VDAnimation

struct ContentView: View {

    var body: some View {
        VStack {
            LoaderAnimation()
            DotsAnimation()
            InteractiveAnimation()
            ComplexMovement()
            UIKitExample()
        }
        .padding()
        .onAppear {
            ColorInterpolationType.default = .okLCH
        }
    }
}

#Preview {
    ContentView()
}
