import Foundation
import Logging

extension SSESession {
    enum ChunkCollectingState: Sendable {
        case badFormat
        case incomplete(String)
        case completed(String)
    }
    protocol ChunkCollector: Sendable {
        func onDataReceived(_ data: Data) async -> [ChunkCollectingState]
    }
    
    actor DefaultChunkCollector: ChunkCollector {
        let logger: Logger
        private var incompleteMessage: String?
        
        init(logger: Logger) {
            self.logger = logger
        }
        
        func onDataReceived(_ data: Data) -> [ChunkCollectingState] {
            guard let message = String(data: data, encoding: .utf8) else {
                logW { "unknown data encoding \(data)" }
                return [.badFormat]
            }
            logD { "got message \(message)" }
            
            let lastChunkIsComplete = message.hasSuffix("\n\n")
            let chunks = message.split(separator: "\n\n")
            
            return chunks.enumerated().compactMap { (index, chunk) -> ChunkCollectingState? in
                guard !chunk.isEmpty else {
                    return nil
                }
                if index + 1 == chunks.count {
                    if lastChunkIsComplete {
                        return onDataReceived(chunk + "\n\n")
                    } else {
                        return onDataReceived(String(chunk))
                    }
                } else {
                    return onDataReceived(chunk + "\n\n")
                }
            }
    }
    
    func onDataReceived(_ message: String) -> ChunkCollectingState {
        logD { "processing chunk \(message)" }
        let prefix = "data: "
        if message.hasPrefix(prefix) {
            if let incomplete = incompleteMessage {
                logW { "got new message when had an incomplete one, skipping incomplete one [incomplete: \(incomplete), received: \(message)]" }
                incompleteMessage = nil
            }
            let formatted = String(message.dropFirst(prefix.count))
            if formatted.hasSuffix("\n\n") {
                return .completed(formatted)
            } else {
                incompleteMessage = formatted
                return .incomplete(formatted)
            }
        } else {
            if let incomplete = incompleteMessage {
                if message.hasSuffix("\n\n") {
                    incompleteMessage = nil
                    return .completed(incomplete + message)
                } else {
                    let formatted = incomplete + message
                    incompleteMessage = formatted
                    return .incomplete(formatted)
                }
            } else {
                logW { "unknown message format for message: \(message)" }
                return .badFormat
            }
        }
    }
    }
}

extension SSESession.DefaultChunkCollector: Loggable {}
