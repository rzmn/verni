import DataTransferObjects

public struct SpendingsHistoryUpdate: LongPollQuery {
    public struct Update: Decodable {
        public enum Category: Decodable {
            case spendings(uid: UserDto.ID)

            public init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                let components = value.split(separator: "_")
                guard components.count == 2 && components[0] == "spendings" else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: [],
                            debugDescription: "should have format like '\(Category.spendings(uid: "uid").stringValue)'")
                    )
                }
                self = .spendings(uid: String(components[1]))
            }

            var stringValue: String {
                switch self {
                case .spendings(let uid):
                    return "spendings_\(uid)"
                }
            }
        }
        let category: Category
    }
    private let uid: UserDto.ID

    public init(uid: UserDto.ID) {
        self.uid = uid
    }

    public var method: String {
        "/spendings/subscribe"
    }

    public func updateIsRelevant(_ update: Update) -> Bool {
        true
    }

    public var eventId: String {
        Update.Category.spendings(uid: uid).stringValue
    }
}
