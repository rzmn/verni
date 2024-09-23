import Foundation

enum AuthenticatedViewActionType {
    case onAddExpenseTap
    case onTabSelected(index: Int)
}

@MainActor struct AuthenticatedViewActions {
    let state: Published<AuthenticatedState>.Publisher
    let handle: @MainActor (AuthenticatedViewActionType) -> Void
}
