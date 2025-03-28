import Entities
import Api

struct Push: Decodable {
    enum CodingKeys: String, CodingKey {
        case payload = "d"
    }
    let payload: PushPayload
}

enum PushPayload {
    case spendingCreated(Components.Schemas.CreateSpendingPushPayload.CsPayload)
    case spendingGroupCreated(Components.Schemas.CreateSpendingGroupPushPayload.CsgPayload)
}

extension PushPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case spendingCreated = "cs"
        case spendingGroupCreated = "csg"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let payload = try container.decodeIfPresent(
            Components.Schemas.CreateSpendingPushPayload.CsPayload.self,
            forKey: .spendingCreated
        ) {
            self = .spendingCreated(payload)
        } else if let payload = try container.decodeIfPresent(
            Components.Schemas.CreateSpendingGroupPushPayload.CsgPayload.self,
            forKey: .spendingGroupCreated
        ) {
            self = .spendingGroupCreated(payload)
        } else {
            throw DecodingError.valueNotFound(
                PushPayload.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.spendingCreated, CodingKeys.spendingGroupCreated],
                    debugDescription: "no value found for push payload"
                )
            )
        }
    }
}
