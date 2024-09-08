import Foundation

enum AuthenticatedViewActionType {
    case onAddExpenseTap
    case onTabSelected(index: Int)
}

struct AuthenticatedViewActions {
    let state: Published<AuthenticatedState>.Publisher
    let handle: @MainActor (AuthenticatedViewActionType) -> Void
}
