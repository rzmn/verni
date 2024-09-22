import Domain

struct Push: Decodable {
    enum CodingKeys: String, CodingKey {
        case payload = "d"
    }
    let payload: PushPayload
}

enum PushPayload {
    case friendRequestHasBeenAccepted(FriendRequestHasBeenAccepted)
    case gotFriendRequest(GotFriendRequest)
    case newExpenseReceived(NewExpenseReceived)
}

extension PushPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case type = "t"
        case payload = "p"
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
                try container.decode(FriendRequestHasBeenAccepted.self, forKey: .payload)
            )
        case .gotFriendRequest:
            self = .gotFriendRequest(
                try container.decode(GotFriendRequest.self, forKey: .payload)
            )
        case .newExpenseReceived:
            self = .newExpenseReceived(
                try container.decode(NewExpenseReceived.self, forKey: .payload)
            )
        }
    }
}

extension PushPayload {
    struct FriendRequestHasBeenAccepted: Decodable {
        let target: User.Identifier

        enum CodingKeys: String, CodingKey {
            case target = "t"
        }
    }
}

extension PushPayload {
    struct GotFriendRequest: Decodable {
        let sender: User.Identifier

        enum CodingKeys: String, CodingKey {
            case sender = "s"
        }
    }
}

extension PushPayload {
    struct NewExpenseReceived: Decodable {
        let spendingId: Spending.Identifier
        let authorId: User.Identifier
        let cost: Int64

        enum CodingKeys: String, CodingKey {
            case spendingId = "d"
            case authorId = "u"
            case cost = "c"
        }
    }
}
