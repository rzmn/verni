import Domain
import Foundation

public protocol UrlResolver: AnyObject {
    func canResolve(url: AppUrl) async -> Bool
    func resolve(url: AppUrl) async
}

public actor UrlResolverContainer {
    private var resolvers: [UrlResolver] = []

    public init() {}

    public func add(_ resolver: UrlResolver) {
        guard resolvers.allSatisfy({ $0 !== resolver }) else {
            return
        }
        resolvers.append(resolver)
    }

    public func remove(_ resolver: UrlResolver) {
        resolvers.removeAll {
            $0 === resolver
        }
    }
}

extension UrlResolverContainer: UrlResolver {
    public func canResolve(url: AppUrl) async -> Bool {
        for resolver in resolvers {
            guard await resolver.canResolve(url: url) else {
                continue
            }
            return true
        }
        return false
    }

    public func resolve(url: AppUrl) async {
        for resolver in resolvers {
            guard await resolver.canResolve(url: url) else {
                continue
            }
            return await resolver.resolve(url: url)
        }
    }
}
