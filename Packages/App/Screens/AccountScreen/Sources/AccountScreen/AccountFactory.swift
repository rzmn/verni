import AppBase
import DI

public protocol AccountFactory: Sendable {
    func create() async -> any ScreenProvider<AccountEvent, AccountView>
}

public final class DefaultAccountFactory: AccountFactory {
    private let di: ActiveSessionDIContainer

    public init(di: ActiveSessionDIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<AccountEvent, AccountView> {
        await AccountModel(di: di)
    }
}
