import AppLayer
internal import DefaultAppLayer
internal import DefaultDomainLayer
internal import DefaultDataLayer
internal import DefaultInfrastructureLayer

@MainActor public final class Assembly {
    public let appFactory: AppFactory
    
    @MainActor public init(
        bundleId: String,
        appGroupId: String
    ) throws {
        let infrastructure = DefaultInfrastructureLayer()
        let data = try DefaultDataLayer(
            infrastructure: infrastructure,
            bundleId: bundleId,
            appGroupId: appGroupId
        )
        appFactory = DefaultAppFactory {   
            return await DefaultSandboxDomainLayer(
                infrastructure: infrastructure,
                data: data
            )
        }
    }
}

