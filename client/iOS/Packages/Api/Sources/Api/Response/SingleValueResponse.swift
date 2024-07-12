import Foundation

struct SingleValueResponse<T: Decodable>: Decodable, Response {
    let value: T

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(T.self)
    }

    init(value: T) {
        self.value = value
    }

    static var overridenValue: SingleValueResponse<T>? {
        nil
    }
}
