import Api
import ApiService

public final class DefaultApiFactory: Sendable {
    private let service: ApiService
    private let impl: DefaultApi

    public init(service: ApiService) {
        self.service = service
        self.impl = DefaultApi(service: service)
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any ApiProtocol {
        impl
    }

    public func longPoll() -> any LongPoll {
        DefaultLongPoll(api: impl)
    }
}
