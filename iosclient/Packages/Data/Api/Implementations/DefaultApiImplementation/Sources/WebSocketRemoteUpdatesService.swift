import Api
import Convenience
import AsyncExtensions
import Logging

actor WebSocketRemoteUpdatesService {
    var source: any EventSource<RemoteUpdate> {
        publisher
    }
    private let publisher: EventPublisher<RemoteUpdate>

    let logger: Logger
    private let taskFactory: TaskFactory

    init(taskFactory: TaskFactory, logger: Logger) async {
        self.logger = logger.with(prefix: "[ws] ")
        self.taskFactory = taskFactory
        self.publisher = EventPublisher()
    }
}

extension WebSocketRemoteUpdatesService: Loggable {}
