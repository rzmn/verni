import Domain
import DI
import UIKit
import Logging
import AppBase
import SwiftUI
internal import SignInFlow
internal import SignUpFlow
internal import DesignSystem
internal import UnauthenticatedFlow

actor AuthenticatedFlow {}

public actor AppFlow {
    public let logger = Logger.shared.with(prefix: "[model.app] ")
    private let di: DIContainer
    private let authUseCase: any AuthUseCaseReturningActiveSession
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
    private let unauthenticatedFlow: UnauthenticatedFlow
    private let store: Store<AppState<AuthenticatedFlow>, AppUserAction<AuthenticatedFlow>>

    public init(di: DIContainer) async {
        self.di = di
        authUseCase = await di.authUseCase()
        unauthenticatedFlow = await UnauthenticatedFlow(
            di: di,
            signInFlowFactory: DefaultSignInFlowFactory(
                di: di,
                haptic: DefaultHapticManager(),
                signUpFlowFactory: DefaultSignUpFlowFactory(
                    di: di,
                    haptic: DefaultHapticManager()
                )
            )
        )
        await MainActor.run {
            setupAppearance()
            AvatarView.repository = di.appCommon.avatarsRepository
        }
        store = await Store(
            current: .unauthenticated,
            reducer: Self.reducer()
        )
    }
}

extension AppFlow: SUIFlow {
    public typealias FlowResult = Void

    @ViewBuilder @MainActor
    public func instantiate(handler: @escaping @MainActor (FlowResult) -> Void) -> some View {
        AppView(
            store: store
        ) {
            self.unauthenticatedFlow.instantiate { session in
                self.authenticate(container: session)
            }
        } authenticatedView: { _ in
            Text("hello from auth")
        }
    }

    @MainActor private func authenticate(container: ActiveSessionDIContainer) {

    }
}

extension AppFlow {
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
