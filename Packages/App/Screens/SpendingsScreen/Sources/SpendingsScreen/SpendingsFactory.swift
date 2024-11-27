import AppBase
import DI

public protocol SpendingsFactory: Sendable {
    func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView>
}

public final class DefaultSpendingsFactory: SpendingsFactory {
    private let di: AuthenticatedDomainLayerSession
    private let haptic: HapticManager

    public init(di: AuthenticatedDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView> {
        await SpendingsModel(di: di, haptic: haptic)
    }
}
