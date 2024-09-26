import Domain
import DI
import UIKit
import Logging
import AppBase
import SwiftUI
internal import DesignSystem
internal import UnauthenticatedFlow

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

    public init(di: DIContainer) async {
        self.di = di
        authUseCase = await di.authUseCase()
        unauthenticatedFlow = await UnauthenticatedFlow(di: di)
        await MainActor.run {
            setupAppearance()
            AvatarView.repository = di.appCommon.avatarsRepository
        }
    }
}

extension AppFlow: SUIFlow {
    public typealias FlowResult = Void

    @ViewBuilder @MainActor
    public func instantiate(handler: @escaping @MainActor (FlowResult) -> Void) -> some View {
        AppView(
            store: Store(
                current: .unauthenticated,
                handle: { _ in }
            )
        ) {
            self.unauthenticatedFlow.instantiate { session in
                self.authenticate(container: session)
            }
        } authenticatedView: { (session: NSObject) in
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

