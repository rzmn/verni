import Domain
import DI
import UIKit
import Logging
internal import LaunchFlow
internal import AppBase
internal import Routing

public actor App {

    public let logger = Logger.shared.with(prefix: "[model.app] ")
    private let appRouter: AppRouter
    private let di: DIContainer
    private var urlResolvers = UrlResolverContainer()

    public init(di: DIContainer, on window: UIWindow) async {
        self.appRouter = await AppRouter(window: window)
        self.di = di
    }

    public func start() async {
        logI { "launching app" }
        let launchModel = await LaunchModel(di: di, appRouter: appRouter)

        if let authenticatedSession = await launchModel.perform() {
            logI { "starting authenticated session \(authenticatedSession)" }
        } else {
            performAuth()
        }
    }

    private func performAuth() {
        Task.detached { [weak self] in
            guard let self else { return }
            await doPerformAuth()
        }
    }

    private func doPerformAuth() async {
        logI { "starting authentication session" }
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
