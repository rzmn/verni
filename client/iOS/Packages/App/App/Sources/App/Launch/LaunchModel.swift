import UIKit
import Domain
import DI
internal import DesignSystem
internal import ProgressHUD

actor LaunchModel {
    private let authUseCase: any AuthUseCaseReturningActiveSession

    init(di: DIContainer, appRouter: AppRouter) async {
        authUseCase = di.authUseCase()
    }

    func performFlow() async -> ActiveSessionDIContainer? {
        await setupAppearance()
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

extension LaunchModel {
    @MainActor
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .font: UIFont.p.title3,
            .foregroundColor: UIColor.p.accent
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.p.primary,
            .font: UIFont.p.title1
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.p.primary,
            .font: UIFont.p.title2
        ]
        UINavigationBar.appearance().standardAppearance = appearance

        ProgressHUD.animationType = .circleStrokeSpin
        ProgressHUD.colorAnimation = .p.accent
        UIImage(systemName: "network.slash").flatMap {
            ProgressHUD.imageError = $0.withTintColor(.p.accent, renderingMode: .alwaysOriginal)
        }
        ProgressHUD.fontStatus = .p.title3
        ProgressHUD.colorStatus = .p.primary
        ProgressHUD.mediaSize = 44
        
    }
}
