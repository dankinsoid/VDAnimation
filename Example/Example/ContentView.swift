import SwiftUI
import VDAnimation
import AVFoundation
import CoreImage

struct _ContentView: View {

    @StateObject
    private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            LoaderAnimation()
            DotsAnimation()
            PathAnimation()
            InteractiveAnimation()
            ComplexMovement()
            UIKitExample()
        }
        .padding()
        .background(
            CameraView(image: $viewModel.currentFrame)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            ColorInterpolationType.default = .okLCH
        }
    }
}

struct ContentView: View {

    @StateObject
    private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text("Camera Preview")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.white
                .opacity(0.2)
                .cornerRadius(30)
                .background(
                    Backdrop()
                        .blur(radius: 5.0, opaque: false)
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            CameraView(image: $viewModel.currentFrame)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            ColorInterpolationType.default = .okLCH
        }
    }
}

struct Backdrop: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIBackdrop { UIBackdrop() }
    func updateUIView(_ uiView: UIBackdrop, context: Context) {}
}


final class UIBackdrop: UIView {
    
    class override var layerClass: AnyClass {
        NSClassFromString("CABackdropLayer") ?? CALayer.self
    }
}

struct CameraView: View {
    
    @Binding var image: CGImage?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let image {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            switch colorScheme {
            case .light:
                Color.white
            case .dark:
                Color.black
            @unknown default:
                Color.black
            }
        }
    }
}


class ViewModel: ObservableObject {
    
    @Published
    var currentFrame: CGImage?
    
    private let cameraManager = CameraManager()
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        for await image in cameraManager.previewStream {
            Task { @MainActor in
                currentFrame = image
            }
        }
    }
}

class CameraManager: NSObject {
    
    private let captureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)

    private var sessionQueue = DispatchQueue(label: "video.preview.session")
    
    private var addToPreviewStream: ((CGImage) -> Void)?
    
    lazy var previewStream: AsyncStream<CGImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { cgImage in
                continuation.yield(cgImage)
            }
        }
    }()
    
    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    override init() {
        super.init()
        
        Task {
            await configureSession()
            await startSession()
        }
        
    }
    
    private func configureSession() async {
        guard await isAuthorized,
              let systemPreferredCamera,
              let deviceInput = try? AVCaptureDeviceInput(device: systemPreferredCamera)
        else { return }
        
        captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
       
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        guard captureSession.canAddInput(deviceInput) else {
            return
        }
        
        guard captureSession.canAddOutput(videoOutput) else {
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)

        //For a vertical orientation of the camera stream
        if #available(iOS 17.0, *) {
            videoOutput.connection(with: .video)?.videoRotationAngle = 90
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    private func startSession() async {
        guard await isAuthorized else { return }
        captureSession.startRunning()
    }
    
    private func rotate(by angle: CGFloat, from connection: AVCaptureConnection) {
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        if #available(iOS 17.0, *) {
            connection.videoRotationAngle = angle
        } else {
            // Fallback on earlier versions
        }
    }

}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let currentFrame = sampleBuffer.cgImage else {
            print("Can't translate to CGImage")
            return
        }
        addToPreviewStream?(currentFrame)
    }
    
}


extension CMSampleBuffer {
    var cgImage: CGImage? {
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self)
        guard let imagePixelBuffer = pixelBuffer else { return nil }
        return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage
    }
}

extension CIImage {
    var cgImage: CGImage? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return cgImage
    }
}

#Preview {
    ContentView()
}
