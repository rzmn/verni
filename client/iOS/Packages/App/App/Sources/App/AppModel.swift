import Domain
import DI
import UIKit
import Logging
internal import AppBase
internal import DesignSystem
internal import AuthenticatedFlow
internal import UnauthenticatedFlow

public actor App {
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

    public init(di: DIContainer) async {
        self.di = di
        authUseCase = await di.authUseCase()
    }

    public func start(on window: UIWindow) async {
        let router = await AppRouter(window: window)
        logI { "launching app" }
        let avatarsRepository = di.appCommon.avatarsRepository
        Task { @MainActor in
            SetupAppearance()
            AvatarView.repository = avatarsRepository
        }
        do {
            await startAuthorizedSession(
                session: try await authUseCase.awake(),
                router: router
            )
        } catch {
            switch error {
            case .hasNoSession:
                return await startAnonynousSession(router: router)
            }
        }
    }

    private func startAuthorizedSession(session: ActiveSessionDIContainer, router: AppRouter) async {
        currentSession = session
        logI { "starting authenticated session \(session)" }
        let flow = await AuthenticatedFlow(di: session, router: router)
        await urlResolvers.add(flow)
        switch await flow.perform() {
        case .logout:
            await urlResolvers.remove(flow)
            await startAnonynousSession(router: router)
        }
    }

    private func startAnonynousSession(router: AppRouter) async {
        currentSession = nil
        let unauthenticated = await UnauthenticatedFlow(di: di, router: router)
        await startAuthorizedSession(session: await unauthenticated.perform(), router: router)
    }
}

extension App {
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

extension App: Loggable {}
