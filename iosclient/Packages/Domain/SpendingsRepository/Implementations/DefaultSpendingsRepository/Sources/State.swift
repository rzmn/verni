import Entities
import SyncEngine

struct State {
    struct GroupParticipantIdentifier: Hashable {
        let groupId: SpendingGroup.Identifier
        let userId: User.Identifier
    }
    var spendingGroupsOrder: OrderedSequenceCRDT<SpendingGroup.Identifier>
    var spendingGroups: [SpendingGroup.Identifier: LastWriteWinsCRDT<SpendingGroup>]

    var groupParticipantsOrder: [SpendingGroup.Identifier: OrderedSequenceCRDT<User.Identifier>]
    var groupParticipants: [GroupParticipantIdentifier: LastWriteWinsCRDT<SpendingGroup.Participant>]

    var spendingsOrder: [SpendingGroup.Identifier: OrderedSequenceCRDT<Spending.Identifier>]
    var spendings: [Spending.Identifier: LastWriteWinsCRDT<Spending>]
}
