import Foundation

public struct Avatar: Equatable, Sendable {
    public let id: Identifier

    public init(id: Avatar.Identifier) {
        self.id = id
    }
}

extension Avatar {
    public typealias Identifier = String
}
