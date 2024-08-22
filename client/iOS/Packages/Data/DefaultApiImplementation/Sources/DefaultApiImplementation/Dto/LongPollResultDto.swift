import Api
import Foundation
import DataTransferObjects

enum LongPollResultDto<Update: Decodable>: Decodable {
    case success([Update])
    case failure(LongPollError)

    enum CodingKeys: CodingKey {
        case timeout
        case events
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if try container.decodeIfPresent(String.self, forKey: .timeout) != nil {
            self = .failure(.noUpdates)
        }
        self = .success(
            try container.decode([Failable<Update>].self, forKey: .events)
                .compactMap(\.wrappedValue)
        )
    }
}
