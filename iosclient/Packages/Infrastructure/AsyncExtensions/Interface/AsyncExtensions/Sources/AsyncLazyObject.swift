import Foundation

@globalActor actor LazyInitActor: GlobalActor {
    public static let shared = LazyInitActor()
}

public final class AsyncLazyObject<T: Sendable>: Sendable {
    private let initializer: @Sendable () async -> T
    @LazyInitActor private var instance: T?

    public init(_ initializer: @escaping @Sendable () async -> T) {
        self.initializer = initializer
    }

    public var value: T {
        get async {
            guard let instance = await self.instance else {
                return await Task { @LazyInitActor in
                    let instance = await initializer()
                    self.instance = instance
                    return instance
                }.value
            }
            return instance
        }
    }
}
