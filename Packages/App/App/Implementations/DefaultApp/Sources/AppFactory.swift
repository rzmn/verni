import AppBase
import App
import DomainLayer
internal import DesignSystem

public final class DefaultAppFactory: AppFactory {
    private let domain: @Sendable () async -> SandboxDomainLayer

    public init(
        domain: @Sendable @escaping () async -> SandboxDomainLayer
    ) {
        self.domain = domain
        CustomFonts.registerCustomFonts(class: DefaultAppFactory.self)
    }

    public func create() -> any ScreenProvider<Void, AppView, Void> {
        AppModel(domain: domain)
    }
}
