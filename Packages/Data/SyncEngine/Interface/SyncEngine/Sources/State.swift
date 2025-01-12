//import Domain
//
//struct State {
//    enum UserCRDT {
//        case sandbox(LastWriteWinsCRDT<SandboxUser>)
//        case regular(LastWriteWinsCRDT<User>)
//        
//        static func user(id: User.Identifier, ownerId: User.Identifier) -> Self {
//            if id != ownerId {
//                return .sandbox(LastWriteWinsCRDT<SandboxUser>(initial: nil))
//            } else {
//                return .regular(LastWriteWinsCRDT<User>(initial: nil))
//            }
//        }
//    }
//    struct GroupParticipantIdentifier: Hashable {
//        let groupId: SpendingGroup.Identifier
//        let userId: User.Identifier
//    }
//    
//    var spendingGroupsOrder: OrderedSequenceCRDT<SpendingGroup.Identifier>
//    var spendingGroups: [SpendingGroup.Identifier: LastWriteWinsCRDT<SpendingGroup>]
//    
//    var groupParticipantsOrder: [SpendingGroup.Identifier: OrderedSequenceCRDT<User.Identifier>]
//    var groupParticipants: [GroupParticipantIdentifier: LastWriteWinsCRDT<SpendingGroup.Participant>]
//    
//    var spendingsOrder: [SpendingGroup.Identifier: OrderedSequenceCRDT<Spending.Identifier>]
//    var spendings: [Spending.Identifier: LastWriteWinsCRDT<Spending>]
//    
//    var users: [User.Identifier: UserCRDT]
//}
