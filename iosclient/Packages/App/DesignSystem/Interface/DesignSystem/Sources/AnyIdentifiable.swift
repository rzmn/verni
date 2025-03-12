import SwiftUI

public struct AnyIdentifiable<T>: Identifiable {
    public let value: T
    public let id: String

    public init(value: T, id: String = UUID().uuidString) {
        self.value = value
        self.id = id
    }
}
