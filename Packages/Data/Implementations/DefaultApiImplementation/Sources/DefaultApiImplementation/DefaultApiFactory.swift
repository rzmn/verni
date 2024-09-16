import Api
import ApiService
import Base
import AsyncExtensions

public final class DefaultApiFactory: Sendable {
    private let service: ApiService
    private let impl: DefaultApi
    private let taskFactory: TaskFactory

    public init(service: ApiService, taskFactory: TaskFactory) {
        self.service = service
        self.taskFactory = taskFactory
        self.impl = DefaultApi(service: service)
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any ApiProtocol {
        impl
    }

    public func longPoll() -> any LongPoll {
        DefaultLongPoll(api: impl, taskFactory: taskFactory)
    }
}
