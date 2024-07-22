import Foundation
import Domain
internal import ApiDomainConvenience
internal import DataTransferObjects
internal import SQLite

enum Schema {
    enum Tokens {
        static let table = Table("tokens")

        enum Keys {
            static let id = Expression<String>("id")
            static let token = Expression<String>("token")
        }
    }

    enum Users {
        static let table = Table("users")

        enum Keys {
            static let id = Expression<String>("id")
            static let payload = Expression<CodableBlob<UserDto>>("payload")
        }
    }

    enum Friends {
        static let table = Table("friends")

        enum Keys {
            static let id = Expression<Int64>("id")
            static let payload = Expression<CodableBlob<[FriendshipKindDto: [UserDto]]>>("payload")
        }
    }

    enum SpendingCounterparties {
        static let table = Table("spendingCounterparties")

        enum Keys {
            static let id = Expression<String>("id")
            static let payload = Expression<CodableBlob<[SpendingsPreviewDto]>>("payload")
        }
    }

    enum SpendingsHistory {
        static let table = Table("spendingHistory")

        enum Keys {
            static let id = Expression<String>("id")
            static let payload = Expression<CodableBlob<[IdentifiableDealDto]>>("payload")
        }
    }
}

struct CodableBlob<T: Codable>: Value {
    typealias Datatype = Blob

    let datatypeValue: Blob

    static var declaredDatatype: String {
        Blob.declaredDatatype
    }

    let value: T

    init(value: T, encoder: JSONEncoder = JSONEncoder()) throws {
        self.value = value
        let data = try encoder.encode(value)
        datatypeValue = Blob(bytes: [UInt8](data))
    }

    static func fromDatatypeValue(_ datatypeValue: Blob) throws -> CodableBlob<T> {
        let data = Data(bytes: datatypeValue.bytes, count: datatypeValue.bytes.count)
        return try CodableBlob(value: try JSONDecoder().decode(T.self, from: data))
    }
}
