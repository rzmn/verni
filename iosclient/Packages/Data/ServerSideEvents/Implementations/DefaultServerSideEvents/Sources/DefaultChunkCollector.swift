import Api
import Convenience
import Logging
import Foundation

fileprivate extension String {
    var droppingSeparatorSuffix: String {
        if hasSuffix(.separator) {
            return String(dropLast(String.separator.count))
        } else {
            return self
        }
    }
    
    static var separator: String {
        "\n\n"
    }
}

actor DefaultChunkCollector: ChunkCollector {
    let logger: Logger
    private var incompleteMessage: String?
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func onDataReceived(_ data: Data) -> [ChunkCollectorOutput] {
        guard let message = String(data: data, encoding: .utf8) else {
            logW { "unknown data encoding \(data)" }
            return [.badFormat]
        }
        logD { "got message \(message)" }
        
        let lastChunkIsComplete = message.hasSuffix(.separator)
        let chunks = message.split(separator: String.separator)
        
        return chunks.enumerated().compactMap { (index, chunk) -> ChunkCollectorOutput? in
            guard !chunk.isEmpty else {
                return nil
            }
            if index + 1 == chunks.count {
                if lastChunkIsComplete {
                    return onDataReceived(chunk + .separator)
                } else {
                    return onDataReceived(String(chunk))
                }
            } else {
                return onDataReceived(chunk + .separator)
            }
        }
    }
    
    func onDataReceived(_ message: String) -> ChunkCollectorOutput {
        logD { "processing chunk \(message)" }
        let prefix = "data: "
        if message.hasPrefix(prefix) {
            if let incomplete = incompleteMessage {
                logW { "got new message when had an incomplete one, skipping incomplete one [incomplete: \(incomplete), received: \(message)]" }
                incompleteMessage = nil
            }
            let formatted = String(message.dropFirst(prefix.count))
            if formatted.hasSuffix(.separator) {
                return .completed(formatted.droppingSeparatorSuffix)
            } else {
                incompleteMessage = formatted
                return .incomplete(formatted)
            }
        } else {
            if let incomplete = incompleteMessage {
                if message.hasSuffix(.separator) {
                    incompleteMessage = nil
                    return .completed((incomplete + message).droppingSeparatorSuffix)
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

extension DefaultChunkCollector: Loggable {}
