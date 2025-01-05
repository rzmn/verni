public struct DescriptorTuple<each D: Descriptor>: Sendable {
    public let content: (repeat each D)

    public init(content: repeat each D) {
        self.content = (repeat each content)
    }
}

public protocol PersistencyFactory: Sendable {
    func awake(host: HostId) async -> Persistency?
    func create<each D: Descriptor>(
        host: HostId,
        descriptors: DescriptorTuple<repeat each D>,
        refreshToken: String
    ) async throws -> Persistency
}
