import AppBase
import DI

public protocol ProfileFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
}

public final class DefaultProfileFactory: ProfileFactory {
    private let di: AuthenticatedDomainLayerSession

    public init(di: AuthenticatedDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions> {
        await ProfileModel(di: di)
    }
}
