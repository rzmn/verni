import AppBase
import DI

public protocol SignInFactory: Sendable {
    func create() async -> any ScreenProvider<SignInEvent, SignInView>
}

public final class DefaultSignInFactory: SignInFactory {
    let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<SignInEvent, SignInView> {
        await SignInModel(di: di)
    }
}
