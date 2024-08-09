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
    private let appRouter: AppRouter
    private let di: DIContainer
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private var urlResolvers = UrlResolverContainer()

    public init(di: DIContainer, on window: UIWindow) async {
        self.appRouter = await AppRouter(window: window)
        self.di = di
        authUseCase = di.authUseCase()
    }

    public func start() async {
        logI { "launching app" }
        Task { @MainActor in
            SetupAppearance()
            AvatarView.repository = di.appCommon().avatarsRepository()
        }
        switch await authUseCase.awake() {
        case .success(let session):
            await startAuthorizedSession(session: session)
        case .failure(let reason):
            switch reason {
            case .hasNoSession:
                return await startAnonynousSession()
            }
        }
    }

    private func startAuthorizedSession(session: ActiveSessionDIContainer) async {
        logI { "starting authenticated session \(session)" }
        switch await AuthenticatedFlow(di: session, router: appRouter).perform() {
        case .logout:
            await startAnonynousSession()
        }
    }

    private func startAnonynousSession() async {
        let unauthenticated = await UnauthenticatedFlow(di: di, router: appRouter)
        await startAuthorizedSession(session: await unauthenticated.perform())
    }
}

extension App {
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
