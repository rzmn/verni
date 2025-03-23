import Entities

public enum SpendingsAction: Sendable {
    case onAppear
    case onSearchTap
    case onOverallBalanceTap

    case balanceUpdated([SpendingsState.Item])

    case onGroupTap(SpendingGroup.Identifier)
}
