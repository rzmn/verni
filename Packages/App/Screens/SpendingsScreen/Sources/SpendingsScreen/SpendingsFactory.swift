import AppBase
import DI

public protocol SpendingsFactory: Sendable {
    func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
}

public final class DefaultSpendingsFactory: SpendingsFactory {
    private let di: AuthenticatedDomainLayerSession

    public init(di: AuthenticatedDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions> {
        await SpendingsModel(di: di)
    }
}
