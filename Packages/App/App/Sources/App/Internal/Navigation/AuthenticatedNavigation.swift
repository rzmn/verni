import SwiftUI
import AppBase
internal import DesignSystem

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
    var id: String {
        switch self {
        case .profile:
            "profile"
        case .spendings:
            "spendings"
        }
    }
    
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

struct AuthenticatedNavigation: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    @Binding private var appearTransitionProgress: CGFloat
    
    init(store: Store<AppState, AppAction>, appearTransitionProgress: Binding<CGFloat>) {
        self.store = store
        _appearTransitionProgress = appearTransitionProgress
    }
    
    var body: some View {
        if let state = store.localState {
            tabs(state: state)
                .bottomBar(
                    config: BottomBarConfig(
                        items: state.tabs
                            .map {
                                switch $0 {
                                case .addExpense:
                                    return .action(.plus, {
                                        store.dispatch(.addExpense)
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
                        }
                    ),
                    appearTransitionProgress: $appearTransitionProgress
                )
                .bottomSheet(
                    preset: Binding(
                        get: {
                            store.localState?.bottomSheet
                        },
                        set: { newValue in
                            store.dispatch(.updateBottomSheet(newValue))
                        }
                    )
                )
                .bottomSheet(
                    preset: Binding(
                        get: { () -> AlertBottomSheetPreset? in
                            if let reason = state.unauthenticatedFailure {
                                return .blocker(title: "unauthorized", subtitle: "\(reason)", actionTitle: "logout") {
                                    store.dispatch(.logoutRequested)
                                }
                            } else {
                                return nil
                            }
                            
                        },
                        set: { _ in }
                    )
                )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder private func tabs(state: AuthenticatedState) -> some View {
        switch state.tab {
        case .profile:
            profileTab(state: state)
        case .spendings:
            spendingsTab(state: state)
        }
    }
    
    @ViewBuilder private func spendingsTab(state: AuthenticatedState) -> some View {
        state.session.spendingsScreen.instantiate { event in
            switch event {
            case .onUserTap:
                break
            }
        }(BottomSheetTransition(progress: $appearTransitionProgress, sourceOffset: .constant(nil), destinationOffset: .constant(nil)))
    }
    
    @ViewBuilder private func profileTab(state: AuthenticatedState) -> some View {
        state.session.profileScreen.instantiate { event in
            switch event {
            case .logout:
                store.dispatch(
                    .updateBottomSheet(
                        .hint(
                            title: "[debug] logout",
                            subtitle: "[debug] sure?",
                            actionTitle: "[debug] confirm",
                            action: {
                                store.dispatch(.logoutRequested)
                            }
                        )
                    )
                )
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
        }()
    }
}
