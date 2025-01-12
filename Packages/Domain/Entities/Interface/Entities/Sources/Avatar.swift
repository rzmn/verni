public struct Avatar: Equatable, Sendable {
    public let id: Identifier
    public let base64: Base64Data

    public init(id: Identifier, base64: Base64Data) {
        self.id = id
        self.base64 = base64
    }
}

extension Avatar {
    public typealias Identifier = String
    public typealias Base64Data = String
}
