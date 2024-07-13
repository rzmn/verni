import Foundation
import DI

actor AuthModel {
    let login: LoginModel

    init(di: DIContainer, appRouter: AppRouter) async {
        login = await LoginModel(di: di, appRouter: appRouter)
    }

    func performFlow() async -> ActiveSessionDIContainer {
        await login.performFlow()
    }
}
