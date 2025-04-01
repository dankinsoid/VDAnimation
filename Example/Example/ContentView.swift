import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack {
            LoaderAnimation()
            DotsAnimation()
            InteractiveAnimation()
            UIKitExample()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
