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
    private var pendingPushToken: String?
    private var currentSession: ActiveSessionDIContainer? {
        didSet {
            if let currentSession, let pendingPushToken {
                self.pendingPushToken = nil
                Task.detached {
                    await self.registerPushToken(session: currentSession, token: pendingPushToken)
                }
            }
        }
    }
    private var urlResolvers = UrlResolverContainer()

    public init(di: DIContainer) {
        self.di = di
        authUseCase = di.authUseCase()
    }

    public func start(on window: UIWindow) async {
        let router = await AppRouter(window: window)
        logI { "launching app" }
        Task { @MainActor in
            SetupAppearance()
            AvatarView.repository = di.appCommon.avatarsRepository
        }
        Task.detached { @MainActor in
            await self.askPushMotificationsPermission()
        }
        switch await authUseCase.awake() {
        case .success(let session):
            await startAuthorizedSession(session: session, router: router)
        case .failure(let reason):
            switch reason {
            case .hasNoSession:
                return await startAnonynousSession(router: router)
            }
        }
    }

    private func askPushMotificationsPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self.logI { "permission for push notifications denied" }
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
    public func registerPushToken(token: String) async {
        if let currentSession {
            await registerPushToken(session: currentSession, token: token)
        } else {
            pendingPushToken = token
        }
    }

    private func registerPushToken(session: ActiveSessionDIContainer, token: String) async {
        await session.pushRegistrationUseCase().registerForPush(token: token)
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
