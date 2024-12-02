import AppBase
import DI

public protocol LogInFactory: Sendable {
    func create() async -> any ScreenProvider<LogInEvent, LogInView, BottomSheetTransition>
}

public final class DefaultLogInFactory: LogInFactory {
    private let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<LogInEvent, LogInView, BottomSheetTransition> {
        await LogInModel(di: di)
    }
}
