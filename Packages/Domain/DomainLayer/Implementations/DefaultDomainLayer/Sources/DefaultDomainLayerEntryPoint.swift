import DomainLayer
import AsyncExtensions
internal import DefaultInfrastructure

final class DefaultDomainLayerEntryPoint: Sendable {
    private let sandboxObject: AsyncLazyObject<SandboxDomainLayer>
    
    init() {
        sandboxObject = AsyncLazyObject {
            await DefaultSandboxDomainLayer(
                shared: try! DefaultSharedDomainLayer(
                    infrastructure: DefaultInfrastructureLayer()
                )
            )
        }
    }
}
