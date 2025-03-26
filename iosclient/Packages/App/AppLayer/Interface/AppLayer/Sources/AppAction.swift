import DesignSystem
import Entities
import Foundation

public enum LaunchSession: Sendable {
    case anonymous(AnySandboxAppSession)
    case authenticated(AnyHostedAppSession)
}

public enum AppAction: Sendable {
    case launch
    case launched(LaunchSession)

    case logoutRequested
    case loggedOut(AnySandboxAppSession)

    case logIn(AnyHostedAppSession, AnonymousState)

    case onAuthorized(AnyHostedAppSession)
    
    case onOpenEditProfile
    case onCloseEditProfile
    case onOpenActivities
    case onCloseActivities
    
    case onUserPreview(User)
    case onShowPreview(User, any UserPreviewScreenProvider)
    case onCloseUserPreview
    
    case onExpenseGroupTap(SpendingGroup.Identifier)
    case onShowGroupExpenses(SpendingGroup.Identifier, any SpendingsGroupScreenProvider)
    case onCloseExpenses

    case showAddExpense(Bool)
    case selectTabAnonymous(AnonymousState.Tab)
    case selectTabAuthenticated(AuthenticatedState.TabItem)
    case updateBottomSheet(AlertBottomSheetPreset?)
    case unauthorized(reason: String)
}
