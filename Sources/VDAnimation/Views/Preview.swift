import SwiftUI

struct ContentView: View {

    @MotionState var opacity = 1.0

    var body: some View {
        WithMotion(_opacity) { value in
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                Text("Hello, world!")
            }
            .foregroundColor(.white)
            .background(Color.blue)
            .padding()
            .opacity(value)
            .onTapGesture {
                $opacity.reverse()
            }
        } motion: {
            Sequential {
                0.5
            }
        }
    }
}

#Preview {
    ContentView()
}
