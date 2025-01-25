import AsyncExtensions
import Entities

public enum CreateSpendingGroupError: Error {
    case participantNotFound(User.Identifier)
    case `internal`(Error)
}

public enum DeleteSpendingGroupError: Error {
    case groupNotFound
    case notAllowed
    case `internal`(Error)
}

public enum CreateSpendingError: Error {
    case groupNotFound
    case notAllowed
    case participantNotFoundInGroup
    case `internal`(Error)
}

public enum DeleteSpendingError: Error {
    case groupNotFound
    case spendingNotFound
    case notAllowed
    case `internal`(Error)
}

public enum SpendingsUpdate: Sendable {
    case spendingGroupsUpdated([SpendingGroup.Identifier])
    case spendingGroupUpdated(SpendingGroup, participants: [SpendingGroup.Participant])
    case spendingsListUpdated(SpendingGroup.Identifier, [Spending.Identifier])
    case spendingUpdated(Spending.Identifier, Spending)
}

public protocol SpendingsRepository: Sendable {
    var updates: any AsyncBroadcast<[SpendingsUpdate]> { get }
    
    subscript(spending: Spending.Identifier) -> Spending? { get async }
    subscript(group groupId: SpendingGroup.Identifier) -> (group: SpendingGroup, participants: [SpendingGroup.Participant])? { get async }
    subscript(spendingsIn group: SpendingGroup.Identifier) -> [Spending]? { get async }
    var groups: [SpendingGroup.Identifier] { get async }
    
    func createGroup(
        participants: [User.Identifier],
        displayName: String?
    ) async throws(CreateSpendingGroupError) -> SpendingGroup.Identifier
    
    func deleteGroup(
        id: SpendingGroup.Identifier
    ) async throws(DeleteSpendingGroupError)
    
    func createSpending(
        in groupId: SpendingGroup.Identifier,
        displayName: String,
        currency: Currency,
        amount: Amount,
        shares: [Spending.Share]
    ) async throws(CreateSpendingError) -> Spending.Identifier
    
    func deleteSpending(
        groupId: SpendingGroup.Identifier,
        spendingId: SpendingGroup.Identifier
    ) async throws(DeleteSpendingError)
}
