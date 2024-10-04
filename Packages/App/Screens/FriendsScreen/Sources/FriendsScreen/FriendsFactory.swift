import AppBase
import DI

public protocol FriendsFactory: Sendable {
    func create() async -> any ScreenProvider<FriendsEvent, FriendsView>
}

public final class DefaultFriendsFactory: FriendsFactory {
    private let di: ActiveSessionDIContainer

    public init(di: ActiveSessionDIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<FriendsEvent, FriendsView> {
        await FriendsModel(di: di)
    }
}
