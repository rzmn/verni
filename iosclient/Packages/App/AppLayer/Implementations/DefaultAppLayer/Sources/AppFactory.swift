import AppBase
import AppLayer
import DomainLayer
internal import DesignSystem

@MainActor public final class DefaultAppFactory: AppFactory {
    private let model: AppModel

    public init(
        domain: @Sendable @escaping () async -> SandboxDomainLayer
    ) {
        self.model = AppModel(domain: domain)
        CustomFonts.registerCustomFonts(class: DefaultAppFactory.self)
    }

    public func view() -> AppView {
        model.view()
    }
}
