import Domain
internal import DesignSystem

enum SpendingsAction {
    case onSearchTap
    case onOverallBalanceTap
    
    case onRefreshBalance
    case balanceUpdated([SpendingsState.Item])
    
    case onUserTap(User)
}
