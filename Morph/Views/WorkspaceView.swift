import SwiftUI
import PhotosUI
import AVKit

public struct WorkspaceView: View {
    @Environment(AppStateManager.self) private var stateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var videoPickerItem: PhotosPickerItem? = nil
    @State private var imagePickerItem: PhotosPickerItem? = nil
    @State private var isExportingVideo = false
    
    public var body: some View {
        @Bindable var stateManager = stateManager
        
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title Header
                    if let mode = stateManager.currentMode {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Button {
                                    stateManager.resetWorkspace()
                                    dismiss()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text("Modes")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                }
                                Spacer()
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                
                                Text(mode.title)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .padding(.top, 8)
                            
                            Text(mode.description)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // SECTION 1: Source Video Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. Source Video")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 20)
                        
                        if let videoURL = stateManager.selectedVideoURL {
                            // Video Preview
                            VStack(spacing: 8) {
                                VideoPreviewCard(videoURL: videoURL)
                                    .frame(height: 200)
                                    .cornerRadius(16)
                                
                                Button {
                                    stateManager.selectedVideoURL = nil
                                    videoPickerItem = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Replace Video Source")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.8))
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Capture/Pick Video Options
                            HStack(spacing: 16) {
                                // Camera Option
                                Button {
                                    stateManager.showCameraView = true
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                        
                                        Text("Record Video")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .glassCardStyle(cornerRadius: 16, borderOpacity: 0.12, backgroundOpacity: 0.25)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Library Picker Option
                                PhotosPicker(
                                    selection: $videoPickerItem,
                                    matching: .videos,
                                    preferredItemEncoding: .compatible
                                ) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                        
                                        Text("Choose Gallery")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .glassCardStyle(cornerRadius: 16, borderOpacity: 0.12, backgroundOpacity: 0.25)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // SECTION 2: Reference Image Selection
                    if let mode = stateManager.currentMode, mode.requiredReferenceCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("2. \(mode.referenceImageLabel)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .textCase(.uppercase)
                                .tracking(1)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // List existing selected reference images
                                    ForEach(0..<stateManager.selectedReferenceImages.count, id: \.self) { index in
                                        let data = stateManager.selectedReferenceImages[index]
                                        if let image = UIImage(data: data) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 88, height: 88)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(.white.opacity(0.15), lineWidth: 1)
                                                    }
                                                
                                                Button {
                                                    stateManager.removeReferenceImage(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.red, .white)
                                                        .font(.system(size: 16))
                                                        .offset(x: 4, y: -4)
                                                }
                                            }
                                            .frame(width: 88, height: 88)
                                        }
                                    }
                                    
                                    // Add picker card if count limit not met
                                    if stateManager.selectedReferenceImages.count < mode.requiredReferenceCount {
                                        PhotosPicker(
                                            selection: $imagePickerItem,
                                            matching: .images
                                        ) {
                                            VStack(spacing: 8) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                                
                                                Text("Add Asset")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                            .frame(width: 88, height: 88)
                                            .glassCardStyle(cornerRadius: 12, borderOpacity: 0.15, backgroundOpacity: 0.3)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // SECTION 3: Custom Prompts
                    if let mode = stateManager.currentMode {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("3. Style Instruction")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                if !mode.promptIsRequired {
                                    Text("(Optional)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack {
                                TextField(
                                    "",
                                    text: $stateManager.promptText,
                                    prompt: Text(mode.promptPlaceholder)
                                        .foregroundStyle(.white.opacity(0.35)),
                                    axis: .vertical
                                )
                                .lineLimit(3...6)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .padding()
                                .glassCardStyle(cornerRadius: 16, borderOpacity: 0.12, backgroundOpacity: 0.25)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // ERROR PANEL
                    if let error = stateManager.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.red)
                            Spacer()
                            Button {
                                stateManager.clearErrorMessage()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(.red.opacity(0.08))
                        .cornerRadius(12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.2), lineWidth: 1)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // GENERATE BUTTON
                    Button {
                        Task {
                            await stateManager.dispatchRenderTask()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "wand.and.stars")
                            Text("Generate Transformation")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.45), radius: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
        }
        .sheet(isPresented: $stateManager.showCameraView) {
            CameraCaptureView { recordedURL in
                stateManager.selectedVideoURL = recordedURL
                stateManager.showCameraView = false
            }
        }
        // PhotosPicker Video Binding
        .onChange(of: videoPickerItem) { oldValue, newValue in
            guard let item = newValue else { return }
            isExportingVideo = true
            Task {
                if let movie = try? await item.loadTransferable(type: URL.self) {
                    // Make a safe copy to cache directory as loadTransferable returns temporary access URLs
                    let fileManager = FileManager.default
                    let destination = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try? fileManager.copyItem(at: movie, to: destination)
                    
                    await MainActor.run {
                        stateManager.selectedVideoURL = destination
                        isExportingVideo = false
                    }
                } else {
                    await MainActor.run {
                        stateManager.errorMessage = "Failed to export video from gallery."
                        isExportingVideo = false
                    }
                }
            }
        }
        // PhotosPicker Image Binding
        .onChange(of: imagePickerItem) { oldValue, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        stateManager.addReferenceImage(data)
                        // Reset image picker selection so the plus button can be re-triggered
                        imagePickerItem = nil
                    }
                }
            }
        }
    }
}

// Simple Helper player container
struct VideoPreviewCard: View {
    let videoURL: URL
    
    var body: some View {
        let player = AVPlayer(url: videoURL)
        VideoPlayer(player: player)
            .onAppear {
                player.play()
                // Loop video
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
            .onDisappear {
                player.pause()
            }
    }
}
