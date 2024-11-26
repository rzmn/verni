import Domain
internal import DesignSystem

enum SpendingsAction {
    case onSearchTap
    case onOverallBalanceTap
    case onUserTap(User)
}
