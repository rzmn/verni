import PersistentStorage
import DataTransferObjects

private struct AnyBox: @unchecked Sendable {
    let value: Any?
}

actor PersistencyMock: Persistency {
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        descriptor: Descriptor<Key, Value>.Index
    ) -> Value? {
        get async {
            await getFunc(descriptor).value as? Value
        }
    }
    
    private nonisolated(unsafe) func getFunc(_ arg: AnyHashable) async -> AnyBox {
        AnyBox(value: await getBlock?(arg))
    }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for descriptor: Descriptor<Key, Value>.Index
    ) async {
        await updateBlock?(descriptor, value)
    }
    
    var getBlock: (@Sendable (AnyHashable) async -> Any?)?
    var updateBlock: ((AnyHashable, Any?) async -> Void)?
    
    var userIdBlock: (@Sendable () async -> UserDto.Identifier)?
    var getRefreshTokenBlock: (@Sendable () async -> String)?
    
    var closeBlock: (@Sendable () async -> Void)?
    var invalidateBlock: (@Sendable () async -> Void)?

    var userId: UserDto.Identifier {
        get async {
            guard let userIdBlock else {
                fatalError("not implemented")
            }
            return await userIdBlock()
        }
    }

    var refreshToken: String {
        get async {
            guard let getRefreshTokenBlock else {
                fatalError("not implemented")
            }
            return await getRefreshTokenBlock()
        }
    }

    func close() async {
        guard let closeBlock else {
            fatalError("not implemented")
        }
        return await closeBlock()
    }

    func invalidate() async {
        guard let invalidateBlock else {
            fatalError("not implemented")
        }
        return await invalidateBlock()
    }
}
