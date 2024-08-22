import Api
import ApiService

public class DefaultApiFactory {
    private let service: ApiService
    private lazy var impl = DefaultApi(service: service)

    public init(service: ApiService) {
        self.service = service
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
