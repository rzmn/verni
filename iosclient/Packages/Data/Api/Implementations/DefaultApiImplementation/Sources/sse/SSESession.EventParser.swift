import Foundation
import Logging
import Api

extension SSESession {
    enum Event: Decodable {
        case connected
        case update(RemoteUpdate)
        case error(Components.Schemas._Error)
        
        enum CodingKeys: String, CodingKey {
            case type
            case update
            case error
            case payload
        }
        
        enum EventType: String, Decodable {
            case connected
            case update
            case error
        }
        
        enum UpdateType: String, Decodable {
            case operationsPulled
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(EventType.self, forKey: .type)
            switch type {
            case .connected:
                self = .connected
            case .update:
                let update = try container.decode(UpdateType.self, forKey: .update)
                switch update {
                case .operationsPulled:
                    self = .update(
                        .newOperationsAvailable(
                            try container.decode(
                                [Components.Schemas.SomeOperation].self,
                                forKey: .payload
                            )
                        )
                    )
                }
            case .error:
                self = .error(
                    try container.decode(
                        Components.Schemas.ErrorResponse.self,
                        forKey: .error
                    ).error
                )
            }
        }
    }
    
    protocol EventParser: Sendable {
        func process(message: String) async throws -> Event
    }
    
    actor DefaultEventParser: EventParser {
        let logger: Logger
        private let decoder = JSONDecoder()
        
        init(logger: Logger) {
            self.logger = logger
        }
        
        func process(message: String) throws -> Event {
            try JSONDecoder().decode(
                Event.self,
                from: Data(message.utf8)
            )
        }
    }
}

extension SSESession.DefaultEventParser: Loggable {}
