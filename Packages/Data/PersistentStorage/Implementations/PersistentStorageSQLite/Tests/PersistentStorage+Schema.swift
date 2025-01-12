import PersistentStorage

extension StorageFactory {
    func create(
        host: UserDto.Identifier,
        refreshToken: String
    ) async throws -> UserStorage {
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
