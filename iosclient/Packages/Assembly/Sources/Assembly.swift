import AppLayer
import Foundation
import DomainLayer
internal import Convenience
internal import DefaultAppLayer
internal import DefaultDomainLayer
internal import DefaultDataLayer
internal import DefaultInfrastructureLayer

@MainActor public final class Assembly {
    public let appModel: AppModel
    
    @MainActor public init() throws {
        let infrastructure = DefaultInfrastructureLayer()
        let appGroupId = "group.com.rzmn.dev.verni"
        infrastructure.logger.logI { "initializing assembly for app group id \(appGroupId)" }
        let dataVersionLabel = "v5"
        let data = try DefaultDataLayer(
            infrastructure: infrastructure,
            dataVersionLabel: dataVersionLabel,
            appGroupId: appGroupId
        )
        let sandboxDomainLayerTask = Task {
            return await DefaultSandboxDomainLayer(
                infrastructure: infrastructure,
                dataVersionLabel: dataVersionLabel,
                data: data
            ) as (any SandboxDomainLayer)
        }
        appModel = DefaultAppModel(domain: sandboxDomainLayerTask)
    }
}

