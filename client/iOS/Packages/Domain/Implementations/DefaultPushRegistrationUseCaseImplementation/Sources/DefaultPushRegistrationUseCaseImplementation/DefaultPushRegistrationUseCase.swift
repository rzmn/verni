import Domain
import PersistentStorage
import Api
internal import DataTransferObjects

public class DefaultPushRegistrationUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultPushRegistrationUseCase: PushRegistrationUseCase {
    public func registerForPush(token: String) async {
        let method = Auth.RegisterForPushNotifications(token: token)
        _ = await api.run(method: method)
    }
}
