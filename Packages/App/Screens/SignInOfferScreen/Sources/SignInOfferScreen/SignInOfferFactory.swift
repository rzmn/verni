import AppBase
import DI

public protocol SignInOfferFactory: Sendable {
    func create() async -> any ScreenProvider<SignInOfferEvent, SignInOfferView>
}

public final class DefaultSignInOfferFactory: SignInOfferFactory {
    private let di: DIContainer

    public init(di: DIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<SignInOfferEvent, SignInOfferView> {
        await SignInOfferModel(di: di)
    }
}
