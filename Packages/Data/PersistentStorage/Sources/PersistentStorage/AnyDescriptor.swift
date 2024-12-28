import Foundation

public struct Index<D: Descriptor>: Sendable, Hashable {
    public let descriptor: D
    public let key: D.Key
}

public protocol Descriptor: Sendable, Hashable {
    associatedtype Key: Sendable & Codable & Hashable
    associatedtype Value: Sendable & Codable

    var id: String { get }
}

extension Descriptor {
    public func index(for key: Key) -> Index<Self> {
        Index(descriptor: self, key: key)
    }
}

public struct Unkeyed: Codable, Hashable, Sendable {}

public struct AnyDescriptor<Key: Sendable & Codable & Hashable, Value: Sendable & Codable>:
    Descriptor
{
    public let id: String
}

extension Descriptor where Key == Unkeyed {
    public var unkeyed: Index<Self> {
        Index(descriptor: self, key: Unkeyed())
    }
}
