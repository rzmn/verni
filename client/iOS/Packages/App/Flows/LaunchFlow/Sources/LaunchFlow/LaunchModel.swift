import UIKit
import Domain
import DI
import Routing
import AppBase
internal import DesignSystem
internal import ProgressHUD

public actor LaunchModel {
    private let authUseCase: any AuthUseCaseReturningActiveSession

    public init(di: DIContainer, appRouter: AppRouter) async {
        authUseCase = di.authUseCase()
    }
}

extension LaunchModel: Flow {
    public func perform() async -> ActiveSessionDIContainer? {
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
