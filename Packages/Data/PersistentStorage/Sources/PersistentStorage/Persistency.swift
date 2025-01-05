public typealias HostId = String

public protocol Persistency: Sendable {
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        index: Index<D>
    ) -> Value? where D.Key == Key, D.Value == Value { get async }

    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        value: Value,
        for index: Index<D>
    ) async where D.Key == Key, D.Value == Value

    var userId: HostId { get async }
    var refreshToken: String { get async }
    func close() async
    func invalidate() async
}
