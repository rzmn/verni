import Domain

enum PushPayload {
    case friendRequestHasBeenAccepted(FriendRequestHasBeenAccepted)
    case gotFriendRequest(GotFriendRequest)
    case newExpenseReceived(NewExpenseReceived)
}

extension PushPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case type = "t"
    }

    enum NotificationType: Int, Codable {
        case friendRequestHasBeenAccepted = 0
        case gotFriendRequest = 1
        case newExpenseReceived = 2
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(NotificationType.self, forKey: .type)
        switch type {
        case .friendRequestHasBeenAccepted:
            self = .friendRequestHasBeenAccepted(
                try FriendRequestHasBeenAccepted(from: decoder)
            )
        case .gotFriendRequest:
            self = .gotFriendRequest(
                try GotFriendRequest(from: decoder)
            )
        case .newExpenseReceived:
            self = .newExpenseReceived(
                try NewExpenseReceived(from: decoder)
            )
        }
    }
}

extension PushPayload {
    struct FriendRequestHasBeenAccepted: Decodable {
        let target: User.ID

        enum CodingKeys: String, CodingKey {
            case target = "t"
        }
    }
}

extension PushPayload {
    struct GotFriendRequest: Decodable {
        let sender: User.ID

        enum CodingKeys: String, CodingKey {
            case sender = "s"
        }
    }
}

extension PushPayload {
    struct NewExpenseReceived: Decodable {
        let spendingId: Spending.ID

        enum CodingKeys: String, CodingKey {
            case spendingId = "d"
        }
    }
}
