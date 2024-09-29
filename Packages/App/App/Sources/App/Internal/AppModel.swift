import Domain
import DI
import UIKit
import Logging
import AppBase
import SwiftUI
internal import SignInOfferScreen
internal import SignInScreen
internal import SignUpScreen
internal import DesignSystem

actor AppModel {
    private var pendingPushToken: Data?
    private var currentSession: ActiveSessionDIContainer? {
        didSet {
            if let currentSession, let pendingPushToken {
                self.pendingPushToken = nil
                Task.detached {
                    await currentSession
                        .pushRegistrationUseCase()
                        .registerForPush(token: pendingPushToken)
                }
            }
        }
    }

    private var urlResolvers = UrlResolverContainer()
    private let store: Store<AppState, AppAction>
    @MainActor private let appDependencies: AppDependencies

    init(di: DIContainer) async {
        appDependencies = await AppDependencies(di: di)
        await MainActor.run {
            AvatarView.repository = di.appCommon.avatarsRepository
        }
        store = await Store(
            state: AppModel.initialState,
            reducer: AppModel.reducer
        )
    }
}

extension AppModel: ScreenProvider {
    typealias FlowResult = Void

    @MainActor func instantiate(handler: @escaping @MainActor (FlowResult) -> Void) -> AppView {
        AppView(
            store: store,
            executorFactory: self,
            dependencies: appDependencies
        )
    }
}

@MainActor extension AppModel: ActionExecutorFactory {
    func executor(for action: AppAction) -> ActionExecutor<AppAction> {
        switch action {
        case .selectTab(let tab):
            selectTab(tab: tab)
        case .changeSignInStackVisibility(let visible):
            changeSignInStackVisibility(visible: visible)
        case .changeSignInStack(let stack):
            changeSignInStack(stack: stack)
        case .acceptedSignInOffer:
            acceptedSignInOffer()
        case .onCreateAccount:
            onCreateAccount()
        case .onCloseSignIn:
            onCloseSignIn()
        case .onAuthorized(let container):
            onAuthorized(container: container)
        }
    }

    private func selectTab(tab: UnauthenticatedState.TabState) -> ActionExecutor<AppAction> {
        .make(action: .selectTab(tab))
    }

    private func changeSignInStackVisibility(visible: Bool) -> ActionExecutor<AppAction> {
        .make(action: .changeSignInStackVisibility(visible: visible))
    }

    private func changeSignInStack(
        stack: [UnauthenticatedState.AccountTabState.SignInStackElement]
    ) -> ActionExecutor<AppAction> {
        .make(action: .changeSignInStack(stack: stack))
    }

    private func acceptedSignInOffer() -> ActionExecutor<AppAction> {
        .make(action: .acceptedSignInOffer) {
            self.store.dispatch(self.changeSignInStackVisibility(visible: true))
        }
    }

    private func onCreateAccount() -> ActionExecutor<AppAction> {
        .make(action: .onCreateAccount) {
            self.store.dispatch(self.changeSignInStack(stack: [.createAccount]))
        }
    }

    private func onCloseSignIn() -> ActionExecutor<AppAction> {
        .make(action: .acceptedSignInOffer) {
            self.store.dispatch(self.changeSignInStackVisibility(visible: false))
            self.store.dispatch(self.changeSignInStack(stack: []))
        }
    }

    private func onAuthorized(container: ActiveSessionDIContainer) -> ActionExecutor<AppAction> {
        .make(action: .onAuthorized(container))
    }
}

extension AppModel {
    public func registerPushToken(token: Data) async {
        if let currentSession {
            await currentSession
                .pushRegistrationUseCase()
                .registerForPush(token: token)
        } else {
            pendingPushToken = token
        }
    }

    public func handle(url: String) async {
        guard let url = AppUrl(string: url) else {
            return
        }
        guard await urlResolvers.canResolve(url: url) else {
            return
        }
        await urlResolvers.resolve(url: url)
    }
}
