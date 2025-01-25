extension Sequence {
    public func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
    
    public func asyncMap<T>(
        _ transform: (Element) async -> T
    ) async -> [T] {
        var values = [T]()
        for element in self {
            await values.append(transform(element))
        }
        return values
    }
    
    public func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            guard let value = try await transform(element) else {
                continue
            }
            values.append(value)
        }
        return values
    }
    
    public func asyncCompactMap<T>(
        _ transform: (Element) async -> T?
    ) async -> [T] {
        var values = [T]()
        for element in self {
            guard let value = await transform(element) else {
                continue
            }
            values.append(value)
        }
        return values
    }
}
