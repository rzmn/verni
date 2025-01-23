import AppBase
import DI
import Logging

public protocol ProfileFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
}

public final class DefaultProfileFactory: ProfileFactory {
    private let di: AuthenticatedDomainLayerSession
    private let logger: Logger

    public init(di: AuthenticatedDomainLayerSession, logger: Logger) {
        self.di = di
        self.logger = logger
    }

    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions> {
        await ProfileModel(di: di, logger: logger)
    }
}
