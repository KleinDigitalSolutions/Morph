import Foundation

public struct RenderTask: Codable, Identifiable, Equatable {
    public enum Status: String, Codable, Equatable {
        case queued = "queued"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
        
        public var displayLabel: String {
            switch self {
            case .queued: return "Queued"
            case .processing: return "Rendering..."
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
    }
    
    public let id: String
    public let mode: ProcessingMode
    public var status: Status
    public var progress: Double // 0.0 to 1.0
    public var progressStage: String
    public let createdAt: Date
    public let originalVideoUrl: String?
    public var resultVideoUrl: String?
    public var errorDescription: String?
    
    public init(
        id: String,
        mode: ProcessingMode,
        status: Status,
        progress: Double,
        progressStage: String,
        createdAt: Date = Date(),
        originalVideoUrl: String? = nil,
        resultVideoUrl: String? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.mode = mode
        self.status = status
        self.progress = progress
        self.progressStage = progressStage
        self.createdAt = createdAt
        self.originalVideoUrl = originalVideoUrl
        self.resultVideoUrl = resultVideoUrl
        self.errorDescription = errorDescription
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case mode
        case status
        case progress
        case progressStage = "progress_stage"
        case createdAt = "created_at"
        case originalVideoUrl = "original_video_url"
        case resultVideoUrl = "result_video_url"
        case errorDescription = "error_description"
    }
}
