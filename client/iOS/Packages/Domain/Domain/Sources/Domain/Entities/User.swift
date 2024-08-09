import UIKit

public struct User: Equatable {
    public let id: ID
    public let status: FriendStatus
    public let displayName: String
    public let avatar: UIImage?

    public init(id: ID, status: FriendStatus = .no, displayName: String, avatar: UIImage?) {
        self.id = id
        self.status = status
        self.displayName = displayName
        self.avatar = avatar
    }
}

extension User {
    public typealias ID = String
}
