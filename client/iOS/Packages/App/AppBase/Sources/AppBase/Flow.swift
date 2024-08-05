import Foundation

public protocol Flow {
    associatedtype Success

    func perform() async -> Success
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
