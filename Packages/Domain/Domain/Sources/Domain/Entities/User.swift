public struct UserPayload: Sendable, Equatable {
    public var displayName: String
    public var avatar: Avatar.Identifier?
    
    public init(displayName: String, avatar: Avatar.Identifier?) {
        self.displayName = displayName
        self.avatar = avatar
    }
}

public struct SandboxUser: Sendable, Equatable {
    public var id: User.Identifier
    public var ownerId: User.Identifier
    public var payload: UserPayload
    public var bindedTo: User.Identifier?
    
    public init(
        id: User.Identifier,
        ownerId: User.Identifier,
        payload: UserPayload,
        bindedTo: User.Identifier?
    ) {
        self.id = id
        self.ownerId = ownerId
        self.payload = payload
        self.bindedTo = bindedTo
    }
}

public struct User: Equatable, Sendable {
    public var id: Identifier
    public var payload: UserPayload

    public init(
        id: Identifier,
        payload: UserPayload
    ) {
        self.id = id
        self.payload = payload
    }
}

extension User {
    public typealias Identifier = String
}
