import AppBase
import DI

public protocol SignInFactory: Sendable {
    func create() async -> any ScreenProvider<SignInEvent, SignInView>
}

public final class DefaultSignInFactory: SignInFactory {
    private let di: AnonymousDomainLayerSession
    private let haptic: HapticManager

    public init(di: AnonymousDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any ScreenProvider<SignInEvent, SignInView> {
        await SignInModel(di: di, haptic: haptic)
    }
}
