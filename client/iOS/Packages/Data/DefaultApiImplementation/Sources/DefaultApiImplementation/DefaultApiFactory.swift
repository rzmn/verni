import Api
import ApiService

public class DefaultApiFactory {
    private let service: ApiService

    public init(service: ApiService) {
        self.service = service
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any ApiProtocol {
        DefaultApi(service: service)
    }

    public func longPoll() -> any LongPoll {
        DefaultLongPoll()
    }
}
