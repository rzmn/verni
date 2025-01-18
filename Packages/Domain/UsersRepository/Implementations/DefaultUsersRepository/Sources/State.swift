import Entities
import SyncEngine

struct State: Sendable {
    enum UserCRDT: Sendable {
        case sandbox(LastWriteWinsCRDT<SandboxUser>)
        case regular(LastWriteWinsCRDT<User>)

        static func user(id: User.Identifier, ownerId: User.Identifier) -> Self {
            if id != ownerId {
                return .sandbox(LastWriteWinsCRDT<SandboxUser>(initial: nil))
            } else {
                return .regular(LastWriteWinsCRDT<User>(initial: nil))
            }
        }
        
        var value: AnyUser? {
            switch self {
            case .regular(let crdt):
                crdt.value.flatMap(AnyUser.regular)
            case .sandbox(let crdt):
                crdt.value.flatMap(AnyUser.sandbox)
            }
        }
    }

    var users: [User.Identifier: UserCRDT]
}
