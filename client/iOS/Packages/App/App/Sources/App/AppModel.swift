import Domain
import Foundation
import Logging
import DI

public actor AppModel {
    public let logger = Logger.shared.with(prefix: "[model.app] ")
    private let appRouter: AppRouter
    private let di: DIContainer
    private var urlResolvers = [UrlResolver]()

    public init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        self.di = di
    }

    public func performFlow() async {
        logI { "launching app" }
        let launchModel = await LaunchModel(di: di, appRouter: appRouter)

        if let authenticatedSession = await launchModel.performFlow() {
            logI { "starting authenticated session" }
            let mainModel = await MainModel(di: authenticatedSession, appRouter: appRouter)
            urlResolvers.append(mainModel)
            switch await mainModel.performFlow() {
            case .loggedOut:
                urlResolvers.remove(mainModel)
                performAuth()
            }
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
        let authModel = await AuthModel(di: di, appRouter: appRouter)
        let authenticatedSession = await authModel.performFlow()
        let mainModel = await MainModel(di: authenticatedSession, appRouter: appRouter)
        urlResolvers.append(mainModel)
        logI { "starting authenticated session" }
        switch await mainModel.performFlow() {
        case .loggedOut:
            urlResolvers.remove(mainModel)
            return performAuth()
        }
    }
}

extension AppModel: UrlResolver {
    public func handle(url: String) async {
        guard let url = InternalUrl(string: url) else {
            return
        }
        if await canResolve(url: url) {
            await resolve(url: url)
        }
    }

    func canResolve(url: InternalUrl) async -> Bool {
        for resolver in urlResolvers {
            guard await resolver.canResolve(url: url) else {
                continue
            }
            return true
        }
        return false
    }
    
    func resolve(url: InternalUrl) async {
        for resolver in urlResolvers {
            guard await resolver.canResolve(url: url) else {
                continue
            }
            return await resolver.resolve(url: url)
        }
    }
}

extension AppModel: Loggable {}
