import Foundation
import SwiftUI
import PhotosUI
import Combine

@Observable
public final class AppStateManager: Sendable {
    // MARK: - State Properties
    public var currentMode: ProcessingMode? = nil
    public var selectedVideoURL: URL? = nil
    public var selectedReferenceImages: [Data] = []
    public var promptText: String = ""
    
    // Active Render Tracking
    public var activeTask: RenderTask? = nil
    public var taskHistory: [RenderTask] = []
    public var uploadProgress: Double = 0.0
    public var isUploading: Bool = false
    public var isGenerating: Bool = false
    public var errorMessage: String? = nil
    
    // Navigation / Presentation
    public var showCameraView: Bool = false
    public var showWorkspace: Bool = false
    public var activeNavigationPath: NavigationPath = NavigationPath()
    
    private let historyKey = "omnistudio.history.key"
    
    public init() {
        loadHistoryFromDisk()
    }
    
    // MARK: - API Orchestration
    
    /// Starts the upload process and binds to WebSocket updates
    @MainActor
    public func dispatchRenderTask() async {
        await startUploadAndProcess()
    }
    
    /// Starts the upload process and binds to WebSocket updates
    @MainActor
    public func startUploadAndProcess() async {
        guard let mode = currentMode else {
            self.errorMessage = "Please select a processing mode first."
            return
        }
        
        guard let videoURL = selectedVideoURL else {
            self.errorMessage = "Please capture or select a source video."
            return
        }
        
        // Validation of requirements
        if mode.promptIsRequired && promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "A prompt description is required for \(mode.title)."
            return
        }
        
        if mode.requiredReferenceCount > 0 && selectedReferenceImages.isEmpty {
            // Environment Swap can bypass if they have a prompt instead
            if mode != .environmentSwap {
                self.errorMessage = "At least one reference image is required for \(mode.title)."
                return
            }
        }
        
        self.errorMessage = nil
        self.isUploading = true
        self.isGenerating = true
        self.uploadProgress = 0.0
        
        do {
            // Step 1: Upload multipart assets
            let task = try await APIClient.shared.startTransformation(
                videoURL: videoURL,
                referenceImages: selectedReferenceImages,
                mode: mode,
                prompt: promptText
            ) { [weak self] progress in
                guard let self = self else { return }
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            
            // Step 2: Transition from uploading to processing
            self.isUploading = false
            self.activeTask = task
            
            // Step 3: Stream progress updates via WebSocket
            try await monitorRenderProgress(taskId: task.id)
            
        } catch {
            self.isUploading = false
            self.isGenerating = false
            self.errorMessage = error.localizedDescription
            self.activeTask = nil
        }
    }
    
    /// Stream WebSocket updates
    @MainActor
    private func monitorRenderProgress(taskId: String) async throws {
        let stream = WebSocketService.shared.streamTaskUpdates(taskId: taskId)
        
        for await updatedTask in stream {
            self.activeTask = updatedTask
            
            if updatedTask.status == .completed {
                // Add to history list
                if !self.taskHistory.contains(where: { $0.id == updatedTask.id }) {
                    self.taskHistory.insert(updatedTask, at: 0)
                    saveHistoryToDisk()
                }
                self.isGenerating = false
                break
            } else if updatedTask.status == .failed {
                self.errorMessage = updatedTask.errorDescription ?? "Render generation failed."
                self.isGenerating = false
                break
            }
        }
    }
    
    /// Trigger manual polling in case WebSockets fail
    @MainActor
    public func pollStatusFallback(taskId: String) async {
        guard isGenerating else { return }
        
        do {
            let updatedTask = try await APIClient.shared.fetchTaskStatus(taskId: taskId)
            self.activeTask = updatedTask
            
            if updatedTask.status == .completed {
                if !self.taskHistory.contains(where: { $0.id == updatedTask.id }) {
                    self.taskHistory.insert(updatedTask, at: 0)
                    saveHistoryToDisk()
                }
                self.isGenerating = false
            } else if updatedTask.status == .failed {
                self.errorMessage = updatedTask.errorDescription ?? "Render generation failed."
                self.isGenerating = false
            } else {
                // Keep polling in 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await pollStatusFallback(taskId: taskId)
            }
        } catch {
            print("Fallback polling failed: \(error)")
        }
    }
    
    // MARK: - State Modifiers
    
    public func resetWorkspace() {
        self.currentMode = nil
        self.selectedVideoURL = nil
        self.selectedReferenceImages = []
        self.promptText = ""
        self.activeTask = nil
        self.uploadProgress = 0.0
        self.isUploading = false
        self.isGenerating = false
        self.errorMessage = nil
    }
    
    public func addReferenceImage(_ data: Data) {
        if let currentMode = currentMode {
            if selectedReferenceImages.count >= currentMode.requiredReferenceCount {
                // Keep history within count constraints
                selectedReferenceImages.removeFirst()
            }
        }
        selectedReferenceImages.append(data)
    }
    
    public func removeReferenceImage(at index: Int) {
        guard index < selectedReferenceImages.count else { return }
        selectedReferenceImages.remove(at: index)
    }
    
    public func clearErrorMessage() {
        self.errorMessage = nil
    }
    
    public func deleteHistoryItem(at offsets: IndexSet) {
        taskHistory.remove(atOffsets: offsets)
        saveHistoryToDisk()
    }
    
    // MARK: - Persistence Helpers
    
    private func saveHistoryToDisk() {
        do {
            let data = try JSONEncoder().encode(taskHistory)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save task history: \(error)")
        }
    }
    
    private func loadHistoryFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([RenderTask].self, from: data)
            self.taskHistory = decoded
        } catch {
            print("Failed to load task history: \(error)")
        }
    }
}
