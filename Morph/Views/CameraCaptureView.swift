import SwiftUI
import AVFoundation

public struct CameraCaptureView: View {
    public let onRecordComplete: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var model = CameraViewModel()
    @State private var recordTime: Int = 0
    @State private var timer: Timer? = nil
    
    public var body: some View {
        ZStack {
            // Camera Preview (or Simulator Mockup)
            #if targetEnvironment(simulator)
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Simulator Mode")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Camera recording is not available in Xcode Simulator. Tap Record to generate a placeholder clip.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            #else
            CameraPreviewView(session: model.captureSession)
                .ignoresSafeArea()
            #endif
            
            // HUD Overlay
            VStack {
                // Top control bar
                HStack {
                    Button {
                        model.stopSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if model.isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text(timeFormatted(seconds: recordTime))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button {
                        model.toggleCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom control bar (Record button)
                VStack {
                    Button {
                        if model.isRecording {
                            stopTimer()
                            model.stopRecording()
                        } else {
                            startTimer()
                            model.startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 76, height: 76)
                            
                            if model.isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.red)
                                    .frame(width: 32, height: 32)
                                    .transition(.scale)
                            } else {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 60, height: 60)
                                    .transition(.scale)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: model.isRecording)
                }
            }
        }
        .onAppear {
            model.setupSession()
            model.onVideoOutput = { fileURL in
                onRecordComplete(fileURL)
                dismiss()
            }
        }
        .onDisappear {
            model.stopSession()
            stopTimer()
        }
    }
    
    private func startTimer() {
        recordTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeFormatted(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Camera Controller ViewModel
@Observable
private final class CameraViewModel: NSObject, AVCaptureFileOutputRecordingDelegate {
    var captureSession = AVCaptureSession()
    var movieOutput = AVCaptureMovieFileOutput()
    var isRecording = false
    var onVideoOutput: ((URL) -> Void)? = nil
    
    private var videoInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "omnistudio.camera.sessionQueue")
    
    func setupSession() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.isRunning else { return }
            
            self.captureSession.beginConfiguration()
            
            // Quality
            self.captureSession.sessionPreset = .hd1920x1080
            
            // Add Video Input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("Failed to access camera device.")
                return
            }
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.videoInput = input
            }
            
            // Add Audio Input
            if let microphone = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: microphone) {
                if self.captureSession.canAddInput(audioInput) {
                    self.captureSession.addInput(audioInput)
                }
            }
            
            // Add Movie Output
            if self.captureSession.canAddOutput(self.movieOutput) {
                self.captureSession.addOutput(self.movieOutput)
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func toggleCamera() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let currentInput = self.videoInput else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(currentInput)
            
            let position: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.addInput(currentInput)
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.videoInput = input
            } else {
                self.captureSession.addInput(currentInput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func startRecording() {
        #if targetEnvironment(simulator)
        isRecording = true
        // Create an empty dummy file for Simulator preview fallback
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        // Just write some placeholder text/dummy bytes to mock a file url
        try? "Dummy Video Data".write(to: fileURL, atomically: true, encoding: .utf8)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.isRecording = false
            self.onVideoOutput?(fileURL)
        }
        return
        #endif
        
        guard let connection = movieOutput.connection(with: .video) else { return }
        // Force portrait orientation output
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording() {
        #if targetEnvironment(simulator)
        return
        #endif
        movieOutput.stopRecording()
        isRecording = false
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingAt fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Camera capture recording started.")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Camera capture recording completed.")
        if let error = error {
            print("Capture error details: \(error)")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onVideoOutput?(outputFileURL)
        }
    }
}

// MARK: - AVCapturePreviewRepresentable
#if !targetEnvironment(simulator)
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
#endif
