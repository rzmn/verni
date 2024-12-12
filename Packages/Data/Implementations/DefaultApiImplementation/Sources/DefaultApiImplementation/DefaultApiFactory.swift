import Api
import ApiService
import Base
import AsyncExtensions
import Logging

public final class DefaultApiFactory: Sendable {
    private let service: ApiService
    private let impl: DefaultApi
    private let taskFactory: TaskFactory
    private let logger: Logger

    public init(service: ApiService, taskFactory: TaskFactory, logger: Logger) {
        self.service = service
        self.logger = logger.with(prefix: "🚀")
        self.taskFactory = taskFactory
        self.impl = DefaultApi(service: service)
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any ApiProtocol {
        impl
    }

    public func longPoll() -> any LongPoll {
        DefaultLongPoll(api: impl, taskFactory: taskFactory, logger: logger)
    }
}
