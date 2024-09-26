import UIKit
import Domain
import DI
import AppBase
import SwiftUI
internal import SignInFlow
internal import DesignSystem
internal import ProgressHUD

public actor UnauthenticatedFlow {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let signInFlow: SignInFlow

    public init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
        signInFlow = await SignInFlow(di: di)
    }
}

extension UnauthenticatedFlow: SUIFlow {
    @ViewBuilder @MainActor
    public func instantiate(handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void) -> some View {
        TabView {
            signInFlow.instantiate { session in
                handler(session)
            }
        }
    }
}
