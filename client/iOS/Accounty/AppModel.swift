import Domain
import Foundation
import Logging
import DI

actor AppModel {
    enum State {
        case launch(LaunchModel)
        case authentication(AuthModel)
        case authenticated(MainModel)
    }
    let logger = Logger.shared.with(prefix: "[model.app] ")
    private let appRouter: AppRouter
    private let di: DIContainer
    private var state: State

    init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        self.di = di
        let launchModel = await LaunchModel(di: di, appRouter: appRouter)
        state = .launch(launchModel)
        logI { "launching app" }
        await launchModel.setAppModel(appModel: self)
        Task.detached {
            await launchModel.start()
        }
    }

    func startAuthenticatedSession(di: ActiveSessionDIContainer) async {
        logI { "starting authenticated session" }
        switch state {
        case .authenticated:
            return assertionFailure("already logged in")
        case .launch, .authentication:
            break
        }
        let mainModel = await MainModel(di: di, appRouter: appRouter)
        await mainModel.setAppModel(self)
        state = .authenticated(mainModel)
        await mainModel.start()
    }

    func startAuthenticationSession() async {
        logI { "starting authentication session" }
        let authModel = await AuthModel(di: di, appRouter: appRouter)
        await authModel.setAppModel(appModel: self)
        state = .authentication(authModel)
        await authModel.start()
    }

    func logout() async {
        logI { "logout" }
        guard case .authenticated = state else {
            return assertionFailure("already logged out")
        }
        await startAuthenticationSession()
    }

    func resolve(url urlString: String) async {
        guard let url = InternalUrl(string: urlString) else {
            return
        }
        switch state {
        case .authentication, .launch:
            break
        case .authenticated(let model):
            await model.resolve(url: url)
        }
    }
}

extension AppModel: Loggable {}
