import PersistentStorage

actor InMemoryCache: Sendable {
    private var storage = [AnyHashable: Any]()

    func get<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        index: Descriptor<Key, Value>.Index
    ) -> Value? {
        guard let cached = storage[index] else {
            return nil
        }
        return cached as? Value
    }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for index: Descriptor<Key, Value>.Index
    ) {
        storage[index] = value
    }
}
