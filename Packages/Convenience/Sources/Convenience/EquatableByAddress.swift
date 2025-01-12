@propertyWrapper
public struct EquatableByAddress<T: Sendable & AnyObject>: Sendable, Equatable {
    public private(set) var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: EquatableByAddress<T>, rhs: EquatableByAddress<T>) -> Bool {
        lhs.wrappedValue === rhs.wrappedValue
    }
}
