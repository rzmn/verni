import Api
import Convenience
import AsyncExtensions
import Logging

public actor DefaultRemoteEventsService {
    private let taskFactory: TaskFactory
    private let logger: Logger
    private var webSocket: WebSocketRemoteUpdatesService?

    init(taskFactory: TaskFactory, logger: Logger) {
        self.taskFactory = taskFactory
        self.logger = logger
    }
}

extension DefaultRemoteEventsService: RemoteUpdatesService {
    public func subscribe() async -> any EventSource<RemoteUpdate> {
        let service: WebSocketRemoteUpdatesService
        if let webSocket {
            service = webSocket
        } else {
            let webSocket = await WebSocketRemoteUpdatesService(
                taskFactory: taskFactory,
                logger: logger
            )
            self.webSocket = webSocket
            service = webSocket
        }
        return await service.source
    }
}
