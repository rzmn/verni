import AppBase
import DI

public protocol SignUpFactory: Sendable {
    func create() async -> any ScreenProvider<SignUpEvent, SignUpView>
}

public final class DefaultSignUpFactory: SignUpFactory {
    let di: DIContainer

    public init(di: DIContainer) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<SignUpEvent, SignUpView> {
        await SignUpModel(di: di)
    }
}
