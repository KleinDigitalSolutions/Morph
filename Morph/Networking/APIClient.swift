import Foundation
import UIKit

public final class APIClient: NSObject, Sendable {
    public static let shared = APIClient()
    
    // Modify this if hosting the FastAPI backend on a different machine/domain
    public var baseURLString: String = "http://localhost:8000"
    
    private let session: URLSession
    
    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 300.0 // Allow up to 5 mins for upload & process
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    /// Deduced WebSocket base URL
    public var webSocketURLString: String {
        let secure = baseURLString.lowercased().hasPrefix("https")
        let host = baseURLString
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
        let scheme = secure ? "wss://" : "ws://"
        return "\(scheme)\(host)"
    }
    
    /// Initiate an AI Transformation by uploading a video and references
    /// - Parameters:
    ///   - videoURL: Local URL of the recorded/selected video file
    ///   - referenceImages: List of image datas to upload as style/guidance assets
    ///   - mode: One of the 4 AI processing modes
    ///   - prompt: Optional text instructions describing the change
    ///   - onUploadProgress: Real-time progress update block for UI tracking (value from 0.0 to 1.0)
    public func startTransformation(
        videoURL: URL,
        referenceImages: [Data],
        mode: ProcessingMode,
        prompt: String?,
        onUploadProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> RenderTask {
        let endpoint = "\(baseURLString)/api/v1/transform"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Write multipart payload to temporary file to avoid loading massive videos in RAM
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".tmp")
        
        guard let stream = OutputStream(url: tempFileURL, append: false) else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to open output stream for multipart body"])
        }
        
        stream.open()
        defer {
            stream.close()
            // Clean up temp file after completion
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        
        // Helper to write text strings
        func write(_ string: String) throws {
            guard let data = string.data(using: .utf8) else { return }
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                    stream.write(baseAddress, maxLength: data.count)
                }
            }
        }
        
        // Helper to write binary data
        func write(_ data: Data) throws {
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                    stream.write(baseAddress, maxLength: data.count)
                }
            }
        }
        
        // Helper to write local file stream in chunks
        func write(fileURL: URL) throws {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            defer { try? fileHandle.close() }
            
            let chunkSize = 1024 * 256 // 256KB chunks
            while let chunk = try fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
                try write(chunk)
            }
        }
        
        // Write Fields
        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"mode\"\r\n\r\n")
        try write("\(mode.rawValue)\r\n")
        
        if let prompt = prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            try write("\(prompt)\r\n")
        }
        
        // Write Reference Images
        for (index, imageData) in referenceImages.enumerated() {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"reference_images\"; filename=\"ref_\(index).jpg\"\r\n")
            try write("Content-Type: image/jpeg\r\n\r\n")
            try write(imageData)
            try write("\r\n")
        }
        
        // Write Video File
        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n")
        try write("Content-Type: video/mp4\r\n\r\n")
        try write(fileURL: videoURL)
        try write("\r\n")
        
        // End boundary
        try write("--\(boundary)--\r\n")
        
        // Get content length
        let attributes = try FileManager.default.attributesOfItem(atPath: tempFileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        
        // Perform Upload with Progress Tracking
        let delegate = onUploadProgress.map { UploadProgressDelegate(onProgress: $0) }
        let (data, response) = try await session.upload(for: request, fromFile: tempFileURL, delegate: delegate)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        
        let decoder = JSONDecoder()
        // Configure decoder to parse ISO8601 dates properly
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = formatter.date(from: dateStr) {
                return date
            }
            // Fallback options
            let fallbackFormatters = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]
            for fStr in fallbackFormatters {
                let f = DateFormatter()
                f.dateFormat = fStr
                if let date = f.date(from: dateStr) {
                    return date
                }
            }
            return Date()
        }
        
        return try decoder.decode(RenderTask.self, from: data)
    }
    
    /// Fallback long-polling method to query task status
    public func fetchTaskStatus(taskId: String) async throws -> RenderTask {
        let endpoint = "\(baseURLString)/api/v1/tasks/\(taskId)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RenderTask.self, from: data)
    }
    
    /// Fetch history of past tasks completed by the backend
    public func fetchTaskHistory() async throws -> [RenderTask] {
        let endpoint = "\(baseURLString)/api/v1/tasks"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([RenderTask].self, from: data)
    }
}

// MARK: - UploadProgressDelegate Helper
private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    let onProgress: @Sendable (Double) -> Void
    
    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(max(1, totalBytesExpectedToSend))
        onProgress(progress)
    }
}
