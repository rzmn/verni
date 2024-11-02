import Base

public struct ImageDto: Codable, Sendable, Equatable {
    public typealias Identifier = String

    public let id: Identifier
    public let base64: String

    public init(id: Identifier, base64: String) {
        self.id = id
        self.base64 = base64
    }
}
