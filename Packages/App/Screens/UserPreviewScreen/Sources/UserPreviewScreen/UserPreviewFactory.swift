import AppBase
import DI

public protocol UserPreviewFactory: Sendable {
    func create() async -> any ScreenProvider<UserPreviewEvent, UserPreviewView>
}

public final class DefaultUserPreviewFactory: UserPreviewFactory {
    private let di: ActiveSessionDIContainer

    public init(di: ActiveSessionDIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<UserPreviewEvent, UserPreviewView> {
        await UserPreviewModel(di: di)
    }
}
