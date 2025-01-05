import Domain

extension FriendshipKindDto {
    public init(domain: FriendshipKind) {
        switch domain {
        case .friends:
            self = .friends
        case .subscriber:
            self = .subscriber
        case .subscription:
            self = .subscription
        }
    }
}

extension FriendshipKind {
    public init(dto: FriendshipKindDto) {
        switch dto {
        case .friends:
            self = .friends
        case .subscription:
            self = .subscription
        case .subscriber:
            self = .subscriber
        }
    }
}
