import UIKit
import Domain
import DI
import DesignSystem

actor LaunchModel {
    private let presenter: LaunchPresenter
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let appRouter: AppRouter

    init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        presenter = await LaunchPresenter(appRouter: appRouter)
        authUseCase = di.authUseCase()
    }

    func performFlow() async -> ActiveSessionDIContainer? {
        switch await authUseCase.awake() {
        case .success(let session):
            return session
        case .failure(let reason):
            switch reason {
            case .hasNoSession:
                return nil
            }
        }
    }
}
