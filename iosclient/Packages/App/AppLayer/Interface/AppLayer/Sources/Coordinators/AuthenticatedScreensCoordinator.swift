import SwiftUI
import UserPreviewScreen
import AppBase
import ProfileScreen
import SpendingsScreen
import AddExpenseScreen
import SpendingsGroupScreen
import ProfileEditingScreen
import DesignSystem

private extension Store<AppState, AppAction> {
    var localState: AuthenticatedState? {
        guard case .launched(let state) = state else {
            return nil
        }
        guard case .authenticated(let state) = state else {
            return nil
        }
        return state
    }
}

private extension AuthenticatedState.TabItem {
    var barTab: BottomBarTab {
        switch self {
        case .profile:
            BottomBarTab(
                id: id,
                icon: .userCircleBorder,
                selectedIcon: .userFill
            )
        case .spendings:
            BottomBarTab(
                id: id,
                icon: .homeBorder,
                selectedIcon: .homeFill
            )
        }
    }
}

private extension AuthenticatedState.TabPosition {
    var transitionValue: CGFloat {
        switch self {
        case .toTheLeft:
            return +1
        case .toTheRight:
            return -1
        default:
            return 0
        }
    }
}

private extension Optional where Wrapped == AuthenticatedState.TabPosition {
    var transitionValue: CGFloat {
        flatMap { $0.transitionValue } ?? 0
    }
}

extension View {
    @ViewBuilder func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

struct AuthenticatedScreensCoordinator: View {
    @Environment(ColorPalette.self) var colors
    @ObservedObject private var store: Store<AppState, AppAction>
    @Binding private var appearTransitionProgress: CGFloat
    
    @State private var spendingsTabTransitionProgress: CGFloat
    @State private var spendingsTabTapCounter: Int = 0
    @State private var profileTabTransitionProgress: CGFloat
    @State private var profileTabTapCounter: Int = 0
    
    init(store: Store<AppState, AppAction>, appearTransitionProgress: Binding<CGFloat>) {
        self.store = store
        _appearTransitionProgress = appearTransitionProgress
        spendingsTabTransitionProgress = (
            store.localState?
                .position(
                    of: {
                        guard case .spendings = $0 else {
                            return false
                        }
                        return true
                    }
                ) as Optional
        ).transitionValue
        profileTabTransitionProgress = (
            store.localState?
                .position(
                    of: {
                        guard case .profile = $0 else {
                            return false
                        }
                        return true
                    }
                ) as Optional
        ).transitionValue
    }
    
    var body: some View {
        contentView
            .bottomSheet(preset: userDialogBottomSheet)
            .fullScreenCover(item: isAddingSpending) { (identifiable: AnyIdentifiable<any AddExpenseScreenProvider>) in
                identifiable.value.instantiate { event in
                    switch event {
                    case .finished:
                        store.dispatch(.showAddExpense(false))
                    }
                }(AddExpenseTransitions())
                    .fullScreenCover(
                        item: userPreviewFromAddExpenseScreen,
                        content: userPreview(from:)
                    )
            }
            .fullScreenCover(
                item: userPreviewFromContentView,
                content: userPreview(from:)
            )
            .bottomSheet(preset: alertBottomSheet)
            .background(
                colors.background.secondary.default.opacity(appearTransitionProgress)
                    .ignoresSafeArea()
            )
            .ifLet(store.localState) { view, state in
                view.environment(state.session.images)
            }
    }
}

// MARK: - full screen covers

extension AuthenticatedScreensCoordinator {
    var isAddingSpending: Binding<AnyIdentifiable<any AddExpenseScreenProvider>?> {
        .constant(
            store.localState
                .flatMap { state -> AnyIdentifiable<any AddExpenseScreenProvider>? in
                    guard state.isAddingSpending else {
                        return nil
                    }
                    return AnyIdentifiable(value: state.session.addExpense, id: "addExpense")
                }
        )
    }
    
    var userPreviewFromAddExpenseScreen: Binding<AnyIdentifiable<any UserPreviewScreenProvider>?> {
        .constant(
            store.localState
                .flatMap(\.externalUserPreview)
                .flatMap { preview -> AnyIdentifiable<any UserPreviewScreenProvider>? in
                    guard case .ready(let user, let provider) = preview else {
                        return nil
                    }
                    return AnyIdentifiable(value: provider, id: user.id)
                }
        )
    }
    
    var userPreviewFromContentView: Binding<AnyIdentifiable<any UserPreviewScreenProvider>?> {
        .constant(
            store.localState?.isAddingSpending == true ? nil : userPreviewFromAddExpenseScreen.wrappedValue
        )
    }
    
    @ViewBuilder func userPreview(from identifiable: AnyIdentifiable<any UserPreviewScreenProvider>) -> some View {
        identifiable.value.instantiate { event in
            switch event {
            case .closed, .spendingGroupCreated:
                store.dispatch(.onCloseUserPreview)
            }
        }(UserPreviewTransitions())
    }
}

// MARK: - bottom sheets

extension AuthenticatedScreensCoordinator {
    var userDialogBottomSheet: Binding<AlertBottomSheetPreset?> {
        Binding(
            get: {
                store.localState?.bottomSheet
            },
            set: { newValue in
                store.dispatch(.updateBottomSheet(newValue))
            }
        )
    }
    
    var alertBottomSheet: Binding<AlertBottomSheetPreset?> {
        Binding(
            get: { () -> AlertBottomSheetPreset? in
                if let reason = store.localState?.unauthenticatedFailure {
                    return .blocker(title: "unauthorized", subtitle: "\(reason)", actionTitle: "logout") {
                        store.dispatch(.logoutRequested)
                    }
                } else {
                    return nil
                }
                
            },
            set: { _ in }
        )
    }
}

// MARK: - tabs

extension AuthenticatedScreensCoordinator {
    @ViewBuilder private var contentView: some View {
        if let state = store.localState {
            tabs(state: state)
                .bottomBar(
                    config: BottomBarConfig(
                        items: state.tabs
                            .map {
                                switch $0 {
                                case .addExpense:
                                    return .action(.plus, {
                                        store.dispatch(.showAddExpense(true))
                                    })
                                case .item(let item):
                                    return .tab(item.barTab)
                                }
                            }
                    ),
                    tab: Binding(
                        get: {
                            state.tab.barTab
                        }, set: { newValue in
                            guard state.tab.id != newValue.id else {
                                switch state.tab {
                                case .profile(let state):
                                    if state.isEditing {
                                        profileTabTapCounter += 1
                                    }
                                case .spendings(let state):
                                    if state.selectedGroup != nil {
                                        spendingsTabTapCounter += 1
                                    }
                                }
                                return
                            }
                            let tabItems = state.tabs.compactMap { tab -> AuthenticatedState.TabItem? in
                                guard case .item(let item) = tab else {
                                    return nil
                                }
                                return item
                            }
                            guard let tab = tabItems.first(where: { $0.id == newValue.id }) else {
                                return assertionFailure("unexpected tab selected")
                            }
                            store.dispatch(.selectTabAuthenticated(tab))
                            withAnimation(.default.speed(3)) {
                                spendingsTabTransitionProgress = (
                                    store.localState?
                                        .position(
                                            of: {
                                                guard case .spendings = $0 else {
                                                    return false
                                                }
                                                return true
                                            }
                                        ) as Optional
                                ).transitionValue
                                profileTabTransitionProgress = (
                                    store.localState?
                                        .position(
                                            of: {
                                                guard case .profile = $0 else {
                                                    return false
                                                }
                                                return true
                                            }
                                        ) as Optional
                                ).transitionValue
                            }
                        }
                    ),
                    appearTransitionProgress: $appearTransitionProgress
                )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder private func tabs(state: AuthenticatedState) -> some View {
        ZStack {
            ForEach(state.tabItems.filter({ $0 != state.tab })) { item in
                tab(for: item, state: state)
            }
            tab(for: state.tab, state: state)
        }
    }
    
    @ViewBuilder private func tab(for item: AuthenticatedState.TabItem, state: AuthenticatedState) -> some View {
        switch item {
        case .spendings(let tabState):
            spendingsTab(state: state, tabState: tabState)
        case .profile(let tabState):
            profileTab(state: state, tabState: tabState)
        }
    }
    
    @ViewBuilder private func spendingsTab(state: AuthenticatedState, tabState: AuthenticatedState.SpendingsState) -> some View {
        if let item = tabState.selectedGroup, case .ready(_, let spendingsGroupScreenProvider) = item {
            spendingsGroupScreenProvider.instantiate { event in
                switch event {
                case .onClose:
                    store.dispatch(.onCloseExpenses)
                }
            }(
                SpendingsGroupTransitions(
                    appear: ModalTransition(
                        progress: $appearTransitionProgress,
                        sourceOffset: .constant(nil),
                        destinationOffset: .constant(nil)
                    ),
                    tapOwnerTab: TapOwnerTabTransition(
                        tapCounter: $spendingsTabTapCounter
                    ),
                    tab: TabTransition(
                        progress: $spendingsTabTransitionProgress
                    )
                )
            )
        } else {
            state.session.spendings.instantiate { event in
                switch event {
                case .onGroupTap(let id):
                    store.dispatch(.onExpenseGroupTap(id))
                }
            }(
                SpendingsTransitions(
                    appear: ModalTransition(
                        progress: $appearTransitionProgress,
                        sourceOffset: .constant(nil),
                        destinationOffset: .constant(nil)
                    ),
                    tab: TabTransition(
                        progress: $spendingsTabTransitionProgress
                    )
                )
            )
        }
    }
    
    @ViewBuilder private func profileTab(state: AuthenticatedState, tabState: AuthenticatedState.ProfileState) -> some View {
        if tabState.isEditing {
            state.session.profileEditing.instantiate { event in
                switch event {
                case .onClose:
                    store.dispatch(.onCloseEditProfile)
                }
            }(
                ProfileEditingTransitions(
                    tab: TabTransition(
                        progress: $profileTabTransitionProgress
                    ),
                    tapOwnerTab: TapOwnerTabTransition(
                        tapCounter: $profileTabTapCounter
                    )
                )
            )
        } else {
            state.session.profile.instantiate { event in
                switch event {
                case .logout:
                    store.dispatch(
                        .updateBottomSheet(
                            .hint(
                                title: .logoutTitle,
                                subtitle: .logoutSubtitle,
                                actionTitle: .logoutConfirm,
                                action: {
                                    store.dispatch(.logoutRequested)
                                }
                            )
                        )
                    )
                case .openEditing:
                    store.dispatch(.onOpenEditProfile)
                case .showQrHint:
                    store.dispatch(
                        .updateBottomSheet(
                            .hint(
                                title: .qrHintTitle,
                                subtitle: .qrHintSubtitle,
                                actionTitle: .sheetClose,
                                action: {
                                    store.dispatch(.updateBottomSheet(nil))
                                }
                            )
                        )
                    )
                case .unauthorized(let reason):
                    store.dispatch(.unauthorized(reason: reason))
                }
            }(
                ProfileTransitions(
                    tab: TabTransition(
                        progress: $profileTabTransitionProgress
                    )
                )
            )
        }
    }
}
