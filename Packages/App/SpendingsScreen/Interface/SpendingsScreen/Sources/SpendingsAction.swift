import Entities

public enum SpendingsAction: Sendable {
    case onSearchTap
    case onOverallBalanceTap

    case balanceUpdated([SpendingsState.Item])

    case onUserTap(User)
}
