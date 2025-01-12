import AsyncExtensions

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
}

public protocol SpendingsRepository: Sendable {
    func createGroup(
        participants: [User.Identifier],
        displayName: String?
    ) async throws(CreateSpendingGroupError)
    
    func deleteGroup(
        id: SpendingGroup.Identifier
    ) async throws(DeleteSpendingGroupError)
    
    func createSpending(
        in groupId: SpendingGroup.Identifier,
        displayName: String,
        currency: Currency,
        amount: Amount,
        shares: [Spending.Share]
    ) async throws(CreateSpendingError)
    
    func deleteSpending(
        groupId: SpendingGroup.Identifier,
        spendingId: SpendingGroup.Identifier
    ) async throws(DeleteSpendingError)
}
