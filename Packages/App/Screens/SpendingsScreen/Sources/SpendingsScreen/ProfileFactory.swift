import AppBase
import DI

public protocol ProfileFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEvent, ProfileView>
}

public final class DefaultProfileFactory: ProfileFactory {
    private let di: AuthenticatedDomainLayerSession
    private let haptic: HapticManager

    public init(di: AuthenticatedDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView> {
        await ProfileModel(di: di, haptic: haptic)
    }
}
