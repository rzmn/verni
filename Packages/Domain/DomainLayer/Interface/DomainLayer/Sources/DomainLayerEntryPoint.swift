public protocol DomainLayerEntryPoint: Sendable {
    var sandbox: SandboxDomainLayer { get async }
}
