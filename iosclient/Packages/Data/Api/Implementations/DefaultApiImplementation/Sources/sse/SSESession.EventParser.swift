import Foundation
import Logging
import Api

extension SSESession {
    actor EventParser {
        let logger: Logger
        private let decoder = JSONDecoder()
        private var connected = false
        
        init(logger: Logger) {
            self.logger = logger
        }
        
        func process(message: String) -> RemoteUpdate? {
            do {
                if connected {
                    return .newOperationsAvailable(
                        try JSONDecoder().decode(
                            NewOperationsAvailableNotification.self,
                            from: Data(message.utf8)
                        ).response
                    )
                } else {
                    let notification = try JSONDecoder().decode(
                        StreamNotification.self,
                        from: Data(message.utf8)
                    )
                    if notification.type == "connected" {
                        connected = true
                        logI { "connection established" }
                    } else {
                        logW { "unknown notification type \(notification.type)" }
                    }
                    return nil
                }
            } catch {
                logE { "failed to decode SSE data error: \(error)" }
                return nil
            }
        }
    }
}

extension SSESession.EventParser {
    struct StreamNotification: Decodable {
        let type: String
    }
    struct NewOperationsAvailableNotification: Decodable {
        let response: [Components.Schemas.SomeOperation]
    }
}

extension SSESession.EventParser: Loggable {}
