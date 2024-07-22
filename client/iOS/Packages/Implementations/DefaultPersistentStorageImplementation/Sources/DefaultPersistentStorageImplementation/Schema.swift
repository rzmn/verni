import Foundation
import Domain
internal import ApiDomainConvenience
internal import DataTransferObjects
internal import SQLite

enum Schema {
    enum Users {
        static let table = Table("users")

        enum Keys {
            static let id = Expression<String>("id")
            static let friendStatus = Expression<Int64>("friendStatus")
        }
    }
    enum Tokens {
        static let table = Table("tokens")

        enum Keys {
            static let id = Expression<String>("id")
            static let token = Expression<String>("token")
        }
    }
}
