import UIKit
import Domain
import DI
import AppBase
import SwiftUI
import SignInFlow
internal import DesignSystem
internal import ProgressHUD

public actor UnauthenticatedFlow {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let signInFlow: any SUIFlow<ActiveSessionDIContainer, () -> SignInView>

    public init(di: DIContainer, signInFlowFactory: SignInFlowFactory) async {
        authUseCase = await di.authUseCase()
        signInFlow = await signInFlowFactory.create()
    }
}

extension UnauthenticatedFlow: SUIFlow {
    @MainActor public func instantiate(handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void) -> some View {
        UnauthenticatedTabsView(
            signInView: self.signInFlow.instantiate { session in
                handler(session)
            }
        )
    }
}
