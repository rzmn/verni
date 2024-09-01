import Foundation

public struct Avatar: Equatable, Sendable {
    public let id: ID

    public init(id: Avatar.ID) {
        self.id = id
    }
}

extension Avatar {
    public typealias ID = String
}
