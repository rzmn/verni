import Foundation
import DI

actor AuthModel {
    private let appRouter: AppRouter
    let login: LoginModel
    let signup: SignupModel

    private weak var appModel: AppModel?

    init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        login = await LoginModel(di: di, appRouter: appRouter)
        signup = await SignupModel(di: di, appRouter: appRouter)
        await login.setAuthModel(self)
    }

    func setAppModel(appModel: AppModel) async {
        self.appModel = appModel
        await login.setAuthModel(self)
        await signup.setAuthModel(authModel: self)
    }

    func startAuthenticatedSession(di: ActiveSessionDIContainer) async {
        await appModel?.startAuthenticatedSession(di: di)
    }

    func start() async {
        await login.start()
    }
}
