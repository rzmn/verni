import AppLayer
import Entities
internal import Convenience

extension AppModel {
    static var reducer: @MainActor @Sendable (AppState, AppAction) -> AppState {
        return { state, action in
            switch action {
            // Session management
            case .launch:
                return state
            case .launched(let session):
                return handleLaunchedSession(session)
            case .onAuthorized(let session):
                return .launched(.authenticated(initialAuthenticatedState(session: session)))
            case .loggedOut(let session):
                return .launched(.anonymous(anonymousState(session: session)))
            case .logoutRequested, .logIn:
                return state
                
            // Tab selection
            case .selectTabAnonymous(let tab):
                return handleAnonymousTabSelection(state: state, tab: tab)
            case .selectTabAuthenticated(let tab):
                return handleAuthenticatedTabSelection(state: state, tab: tab)
                
            // UI State updates
            case .showAddExpense(let addExpense):
                return updateAuthenticatedState(state) { $0.isAddingSpending = addExpense }
            case .unauthorized(let reason):
                return updateAuthenticatedState(state) { $0.unauthenticatedFailure = reason }
            case .updateBottomSheet(let sheet):
                return updateAuthenticatedState(state) { $0.bottomSheet = sheet }
                
            // User preview handling
            case .onUserPreview(let user):
                return updateAuthenticatedState(state) { $0.externalUserPreview = .pending(user) }
            case .onShowPreview(let user, let provider):
                return updateAuthenticatedState(state) { $0.externalUserPreview = .ready(user, provider) }
            case .onCloseUserPreview:
                return updateAuthenticatedState(state) { $0.externalUserPreview = nil }
                
            // Expense group handling
            case .onCloseExpenses:
                return modify(state) { updateSelectedSpendingsGroup(groupPreview: nil, state: &$0) }
            case .onExpenseGroupTap(let id):
                return modify(state) { updateSelectedSpendingsGroup(groupPreview: .pending(id), state: &$0) }
            case .onShowGroupExpenses(let id, let provider):
                return modify(state) { updateSelectedSpendingsGroup(groupPreview: .ready(id, provider), state: &$0) }
            }
        }
    }

    // Helper functions
    @MainActor private static func handleLaunchedSession(_ session: LaunchSession) -> AppState {
        switch session {
        case .anonymous(let session):
            return .launched(.anonymous(anonymousState(session: session)))
        case .authenticated(let session):
            return .launched(.authenticated(initialAuthenticatedState(session: session)))
        }
    }
    
    @MainActor private static func handleAnonymousTabSelection(state: AppState, tab: AnonymousState.Tab) -> AppState {
        guard case .launched(.anonymous(let anonymous)) = state else { return state }
        return .launched(.anonymous(modify(anonymous) { $0.tab = tab }))
    }
    
    @MainActor private static func handleAuthenticatedTabSelection(state: AppState, tab: AuthenticatedState.TabItem) -> AppState {
        guard case .launched(.authenticated(let authenticated)) = state else { return state }
        return .launched(.authenticated(modify(authenticated) { $0.tab = tab }))
    }
    
    @MainActor private static func updateAuthenticatedState(_ state: AppState, update: (inout AuthenticatedState) -> Void) -> AppState {
        modify(state) {
            guard case .launched(.authenticated(var authenticated)) = $0 else { return }
            update(&authenticated)
            $0 = .launched(.authenticated(authenticated))
        }
    }

    @MainActor private static func anonymousState(session: AnySandboxAppSession) -> AnonymousState {
        let authState = AnonymousState.AuthState()
        return AnonymousState(
            session: session,
            tabs: [
                .auth(authState)
            ],
            tab: .auth(authState)
        )
    }

    @MainActor private static func initialAuthenticatedState(session: AnyHostedAppSession) -> AuthenticatedState {
        let spendingsState = AuthenticatedState.SpendingsState()
        return AuthenticatedState(
            session: session,
            tabs: [
                .item(.spendings(spendingsState)),
                .addExpense,
                .item(.profile)
            ],
            tab: .spendings(spendingsState),
            bottomSheet: nil,
            isAddingSpending: false,
            unauthenticatedFailure: nil
        )
    }
    
    @MainActor private static func updateSelectedSpendingsGroup(
        groupPreview: AuthenticatedState.SpendingsGroupPreview?,
        state: inout AppState
    ) {
        guard case .launched(let launched) = state else {
            return
        }
        guard case .authenticated(var authenticated) = launched else {
            return
        }
        authenticated.tabs = authenticated.tabs.map {
            guard case .item(let tab) = $0 else {
                return $0
            }
            guard case .spendings(var state) = tab else {
                return $0
            }
            state.selectedGroup = groupPreview
            return .item(.spendings(state))
        }
        if let tab = authenticated.tabs.compactMap(
            { tab -> AuthenticatedState.TabItem? in
                guard case .item(let tab) = tab else {
                    return nil
                }
                guard case .spendings = tab else {
                    return nil
                }
                return tab
            }
        ).first {
            authenticated.tab = tab
        }
        state = .launched(.authenticated(authenticated))
    }
}
