import Foundation
import Logging

extension SSESession {
    actor ChunkCollector {
        let logger: Logger
        private var incompleteMessage: String?
        
        init(logger: Logger) {
            self.logger = logger
        }
        
        func onDataReceived(_ data: Data) -> String? {
            guard let message = String(data: data, encoding: .utf8) else {
                logW { "unknown data encoding \(data)" }
                return nil
            }
            let prefix = "data: "
            if message.hasPrefix(prefix) {
                if let incomplete = incompleteMessage {
                    logW { "got new message when had an incomplete one, skipping incomplete one [incomplete: \(incomplete), received: \(message)]" }
                    incompleteMessage = nil
                }
                let formatted = String(message.dropFirst(prefix.count))
                if formatted.hasSuffix("\n\n") {
                    return formatted
                } else {
                    incompleteMessage = formatted
                    logI { "got incomplete message \(formatted), waiting for next chunk" }
                    return nil
                }
            } else {
                if let incomplete = incompleteMessage {
                    if message.hasSuffix("\n\n") {
                        incompleteMessage = nil
                        return incomplete + message
                    } else {
                        let formatted = incomplete + message
                        logI { "keep incomplete message \(formatted), waiting for next chunk" }
                        incompleteMessage = formatted
                        return nil
                    }
                } else {
                    logW { "unknown message format for message: \(message)" }
                    return nil
                }
            }
        }
    }
}

extension SSESession.ChunkCollector: Loggable {}
