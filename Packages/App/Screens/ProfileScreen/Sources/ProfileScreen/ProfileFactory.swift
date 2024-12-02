import AppBase
import DI

public protocol ProfileFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEvent, ProfileView, Void>
}

public final class DefaultProfileFactory: ProfileFactory {
    private let di: AuthenticatedDomainLayerSession

    public init(di: AuthenticatedDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView, Void> {
        await ProfileModel(di: di)
    }
}
