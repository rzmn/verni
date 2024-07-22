import Domain
import DataTransferObjects

extension FriendshipKindDto {
    public init(domain: FriendshipKind) {
        switch domain {
        case .friends:
            self = .friends
        case .incoming:
            self = .subscriber
        case .pending:
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
            self = .pending
        case .subscriber:
            self = .incoming
        }
    }
}
