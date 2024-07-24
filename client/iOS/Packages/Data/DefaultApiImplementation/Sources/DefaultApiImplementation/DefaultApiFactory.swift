import Api
import ApiService

public class DefaultApiFactory {
    private let service: ApiService
    private let polling: ApiPolling?

    public init(service: ApiService, polling: ApiPolling? = nil) {
        self.service = service
        self.polling = polling
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any ApiProtocol {
        DefaultApi(service: service, polling: polling)
    }
}
