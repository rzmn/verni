import AppBase
import DI

public protocol LogInFactory: Sendable {
    func create() async -> any ScreenProvider<LogInEvent, LogInView>
}

public final class DefaultLogInFactory: LogInFactory {
    private let di: AnonymousDomainLayerSession
    private let haptic: HapticManager

    public init(di: AnonymousDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any ScreenProvider<LogInEvent, LogInView> {
        await LogInModel(di: di, haptic: haptic)
    }
}
