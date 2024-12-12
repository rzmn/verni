import AppBase
import DI
import Logging

public protocol SpendingsFactory: Sendable {
    func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
}

public final class DefaultSpendingsFactory: SpendingsFactory {
    private let di: AuthenticatedDomainLayerSession
    private let logger: Logger

    public init(di: AuthenticatedDomainLayerSession, logger: Logger) {
        self.di = di
        self.logger = logger
    }

    public func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions> {
        await SpendingsModel(di: di, logger: logger)
    }
}
