import DomainLayer
import AsyncExtensions
internal import DefaultInfrastructure

public final class DefaultDomainLayerEntryPoint: Sendable {
    private let sandboxObject: AsyncLazyObject<SandboxDomainLayer>
    
    init() {
        sandboxObject = AsyncLazyObject {
            let infrastructure = DefaultInfrastructureLayer()
            let shared: DefaultSharedDomainLayer
            do {
                shared = try await DefaultSharedDomainLayer(
                    infrastructure: infrastructure
                )
            } catch {
                let message = "failed to init shared domain layer error: \(error)"
                infrastructure.logger.logE { message }
                fatalError(message)
            }
            return await DefaultSandboxDomainLayer(
                shared: shared
            )
        }
    }
}

extension DefaultDomainLayerEntryPoint: DomainLayerEntryPoint {
    public var sandbox: any SandboxDomainLayer {
        get async {
            await sandboxObject.value
        }
    }
}
