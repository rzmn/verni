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
        infrastructure.logger.logI { "initializing assembly for app group id \(Configuration.appGroupId)" }
        guard let apiEndpoint = URL(string: Configuration.endpoint) else {
            throw InternalError.error("failed to initialize api endpoind url")
        }
        self.urlProvider = UrlProvider(schema: Configuration.appUrlSchema)
        let data = try DefaultDataLayer(
            infrastructure: infrastructure,
            dataVersionLabel: Configuration.dataVersionLabel,
            appGroupId: Configuration.appGroupId,
            apiEndpoint: apiEndpoint
        )
        let sandboxDomainLayerTask = Task {
            return await DefaultSandboxDomainLayer(
                infrastructure: infrastructure,
                dataVersionLabel: Configuration.dataVersionLabel,
                webcredentials: Configuration.webcredentials,
                data: data
            ) as (any SandboxDomainLayer)
        }
        appModel = DefaultAppModel(domain: sandboxDomainLayerTask, urlProvider: urlProvider)
    }
}

