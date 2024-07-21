import Foundation
import DataTransferObjects
import SwiftData

@Model
class PersistentUser {
    typealias ID = String
    var payload: UserDto
    init(payload: UserDto) {
        self.payload = payload
    }

    var id: ID {
        "\(Self.self)"
    }
}

@Model
class PersistentRefreshToken {
    typealias ID = String
    var payload: String
    init(payload: String) {
        self.payload = payload
    }

    var id: ID {
        "\(Self.self)"
    }
}
