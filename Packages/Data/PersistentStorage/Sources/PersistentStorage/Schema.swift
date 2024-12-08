import Foundation

public struct Unkeyed: Codable, Hashable, Sendable {}

public struct Schema<Key: Sendable & Codable & Hashable, Value: Sendable & Codable>: Sendable, Hashable {
    public let id: String
}

extension Schema {
    public struct Index: Sendable, Hashable {
        public let schema: Schema
        public let key: Key
        
        init(schema: Schema, key: Key) {
            self.schema = schema
            self.key = key
        }
    }
    
    public func index(for key: Key) -> Index {
        Index(schema: self, key: key)
    }
}

extension Schema where Key == Unkeyed {
    public var unkeyedIndex: Index {
        Index(schema: self, key: Unkeyed())
    }
}
