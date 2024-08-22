import Foundation

public struct Failable<T: Decodable>: Decodable {
    public let wrappedValue: T?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try? container.decode(T.self)
    }
}
