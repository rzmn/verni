public struct UserPayload: Sendable, Equatable {
    public var displayName: String
    public var avatar: Image.Identifier?
    
    public init(displayName: String, avatar: Image.Identifier?) {
        self.displayName = displayName
        self.avatar = avatar
    }
}

public enum AnyUser: Sendable, Equatable {
    case sandbox(SandboxUser)
    case regular(User)
    
    public var payload: UserPayload {
        switch self {
        case .sandbox(let user):
            user.payload
        case .regular(let user):
            user.payload
        }
    }
}

public struct SandboxUser: Sendable, Equatable {
    public var id: User.Identifier
    public var ownerId: User.Identifier
    public var payload: UserPayload
    public var boundTo: User.Identifier?
    
    public init(
        id: User.Identifier,
        ownerId: User.Identifier,
        payload: UserPayload,
        boundTo: User.Identifier?
    ) {
        self.id = id
        self.ownerId = ownerId
        self.payload = payload
        self.boundTo = boundTo
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
