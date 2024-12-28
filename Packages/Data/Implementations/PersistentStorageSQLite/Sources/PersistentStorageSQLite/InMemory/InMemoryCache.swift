import PersistentStorage

actor InMemoryCache: Sendable {
    private var storage = [AnyHashable: Any]()

    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        index: Index<D>
    ) -> Value? where D.Key == Key, D.Value == Value {
        guard let cached = storage[index] else {
            return nil
        }
        return cached as? Value
    }

    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        value: Value,
        for index: Index<D>
    ) async where D.Key == Key, D.Value == Value {
        storage[index] = value
    }
}
