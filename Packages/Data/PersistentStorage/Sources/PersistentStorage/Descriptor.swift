import Foundation

public struct Unkeyed: Codable, Hashable, Sendable {}

public struct Descriptor<Key: Sendable & Codable & Hashable, Value: Sendable & Codable>: Sendable, Hashable {
    public let id: String
}

extension Descriptor {
    public struct Index: Sendable, Hashable {
        public let descriptor: Descriptor
        public let key: Key
        
        init(descriptor: Descriptor, key: Key) {
            self.descriptor = descriptor
            self.key = key
        }
    }
    
    public func index(for key: Key) -> Index {
        Index(descriptor: self, key: key)
    }
}

extension Descriptor where Key == Unkeyed {
    public var unkeyed: Index {
        Index(descriptor: self, key: Unkeyed())
    }
}
