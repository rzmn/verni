import AppBase
import DI

public protocol SignInFactory: Sendable {
    func create() async -> any ScreenProvider<SignInEvent, SignInView>
}

public final class DefaultSignInFactory: SignInFactory {
    let di: DIContainer

    public init(di: DIContainer) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<SignInEvent, SignInView> {
        await SignInModel(di: di)
    }
}
