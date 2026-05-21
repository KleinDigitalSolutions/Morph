import Foundation
import Combine

public final class WebSocketService: NSObject, Sendable {
    public static let shared = WebSocketService()
    
    private override init() {
        super.init()
    }
    
    /// Stream live updates for a specific task using Swift Concurrency's AsyncStream
    /// - Parameter taskId: The task ID returned from the server
    /// - Returns: An AsyncStream emitting RenderTask updates
    public func streamTaskUpdates(taskId: String) -> AsyncStream<RenderTask> {
        let wsURLString = "\(APIClient.shared.webSocketURLString)/api/v1/tasks/\(taskId)/ws"
        guard let url = URL(string: wsURLString) else {
            return AsyncStream { continuation in
                continuation.finish()
            }
        }
        
        let session = URLSession(configuration: .default)
        let webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
        
        return AsyncStream { continuation in
            let isRunning = Set<String>()
            
            // Set up a task to read messages continuously
            let readTask = Task {
                defer {
                    webSocketTask.cancel(with: .normalClosure, reason: nil)
                    continuation.finish()
                }
                
                while !Task.isCancelled {
                    do {
                        let message = try await webSocketTask.receive()
                        switch message {
                        case .string(let text):
                            guard let data = text.data(using: .utf8) else { continue }
                            
                            let decoder = JSONDecoder()
                            // Set up date decoder strategy
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            decoder.dateDecodingStrategy = .custom { decoder in
                                let container = try decoder.singleValueContainer()
                                let dateStr = try container.decode(String.self)
                                if let date = formatter.date(from: dateStr) {
                                    return date
                                }
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
                            
                            let updatedTask = try decoder.decode(RenderTask.self)
                            continuation.yield(updatedTask)
                            
                            // If task reaches final state, terminate stream
                            if updatedTask.status == .completed || updatedTask.status == .failed {
                                return
                            }
                            
                        case .data(let data):
                            // In case server sends binary frame
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            let updatedTask = try decoder.decode(RenderTask.self, from: data)
                            continuation.yield(updatedTask)
                            
                            if updatedTask.status == .completed || updatedTask.status == .failed {
                                return
                            }
                        @unknown default:
                            break
                        }
                    } catch {
                        // Connection lost or closed
                        print("WebSocket receive error: \(error)")
                        break
                    }
                }
            }
            
            // Cleanup block when the stream consumer cancels or finishes
            continuation.onTermination = { _ in
                readTask.cancel()
                webSocketTask.cancel(with: .goingAway, reason: nil)
            }
        }
    }
}
