public struct Endpoint: Sendable {
    public let path: String

    public init(path: String) {
        if path.hasSuffix("/") {
            self.path = String(path.prefix(path.count - 1))
        } else {
            self.path = path
        }
    }
}
