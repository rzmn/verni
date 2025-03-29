import AppLayer
import Foundation
import DomainLayer
import AppBase
internal import Convenience
internal import DefaultAppLayer
internal import DefaultDomainLayer
internal import DefaultDataLayer
internal import DefaultInfrastructureLayer

@MainActor public final class Assembly {
    public let appModel: AppModel
    public let urlProvider: UrlProvider
    
    @MainActor public init() throws {
        let infrastructure = DefaultInfrastructureLayer()
        let appGroupId = "group.com.rzmn.dev.verni"
        infrastructure.logger.logI { "initializing assembly for app group id \(appGroupId)" }
        guard let apiEndpoint = URL(string: "https://verni.app") else {
            throw InternalError.error("failed to initialize api endpoind url")
        }
        self.urlProvider = UrlProvider(schema: "verni")
        let dataVersionLabel = "v5"
        let data = try DefaultDataLayer(
            infrastructure: infrastructure,
            dataVersionLabel: dataVersionLabel,
            appGroupId: appGroupId,
            apiEndpoint: apiEndpoint
        )
        let sandboxDomainLayerTask = Task {
            return await DefaultSandboxDomainLayer(
                infrastructure: infrastructure,
                dataVersionLabel: dataVersionLabel,
                webcredentials: "verni.app",
                data: data
            ) as (any SandboxDomainLayer)
        }
        appModel = DefaultAppModel(domain: sandboxDomainLayerTask, urlProvider: urlProvider)
    }
}

