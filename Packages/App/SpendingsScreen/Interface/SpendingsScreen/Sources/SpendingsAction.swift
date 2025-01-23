import Entities

public enum SpendingsAction: Sendable {
    case onSearchTap
    case onOverallBalanceTap

    case onRefreshBalance
    case balanceUpdated([SpendingsState.Item])

    case onUserTap(User)
}
