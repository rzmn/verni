import AppBase
import DI

public protocol QrCodeFactory: Sendable {
    func create() async -> any ScreenProvider<QrCodeEvent, QrCodeView>
}

public final class DefaultQrCodeFactory: QrCodeFactory {
    private let di: ActiveSessionDIContainer

    public init(di: ActiveSessionDIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<QrCodeEvent, QrCodeView> {
        await QrCodeModel(di: di)
    }
}
