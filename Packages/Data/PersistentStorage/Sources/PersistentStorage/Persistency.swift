import DataTransferObjects

public protocol Persistency: Sendable {
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        index: Descriptor<Key, Value>.Index
    ) -> Value? { get async }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for index: Descriptor<Key, Value>.Index
    ) async
    
    var userId: UserDto.Identifier { get async }
    var refreshToken: String { get async }
    func close() async
    func invalidate() async
}
