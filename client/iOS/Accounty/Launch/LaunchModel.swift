import UIKit
import Domain
import DI
import DesignSystem

actor LaunchModel {
    private let presenter: LaunchPresenter
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let appRouter: AppRouter

    private weak var appModel: AppModel?

    init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        presenter = await LaunchPresenter(appRouter: appRouter)
        authUseCase = di.authUseCase()
    }

    func setAppModel(appModel: AppModel) {
        self.appModel = appModel
    }

    func start() async {
        await presenter.start()
        await awake()
    }

    private func awake() async {
        guard let appModel else {
            return
        }
        switch await authUseCase.awake() {
        case .success(let session):
            await appModel.startAuthenticatedSession(di: session)
        case .failure(let reason):
            switch reason {
            case .hasNoSession:
                await appModel.startAuthenticationSession()
            }
        }
    }
}
