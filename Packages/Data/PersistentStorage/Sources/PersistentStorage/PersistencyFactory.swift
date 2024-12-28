import DataTransferObjects

public struct DescriptorTuple<each D: Descriptor>: Sendable {
    public let content: (repeat each D)

    public init(content: repeat each D) {
        self.content = (repeat each content)
    }
}

public protocol PersistencyFactory: Sendable {
    func awake(host: UserDto.Identifier) async -> Persistency?
    func create<each D: Descriptor>(
        host: UserDto.Identifier,
        descriptors: DescriptorTuple<repeat each D>,
        refreshToken: String
    ) async throws -> Persistency
}
