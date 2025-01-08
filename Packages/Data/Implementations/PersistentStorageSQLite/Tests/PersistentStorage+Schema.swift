import PersistentStorage

extension PersistencyFactory {
    func create(
        host: UserDto.Identifier,
        refreshToken: String
    ) async throws -> Persistency {
        return try await create(
            host: host,
            descriptors: DescriptorTuple(
                content:
                    Schema.refreshToken,
                    Schema.profile,
                    Schema.users,
            ),
            refreshToken: refreshToken
        )
    }
}
