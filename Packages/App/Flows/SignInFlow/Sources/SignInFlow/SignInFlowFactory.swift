import SignUpFlow
import AppBase
import DI

@MainActor public protocol SignInFlowFactory: Sendable {
    func create() async -> any SUIFlow<ActiveSessionDIContainer, () -> SignInView>
}

public class DefaultSignInFlowFactory: SignInFlowFactory {
    let di: DIContainer
    let signUpFlowFactory: SignUpFlowFactory

    public init(
        di: DIContainer,
        signUpFlowFactory: SignUpFlowFactory
    ) {
        self.di = di
        self.signUpFlowFactory = signUpFlowFactory
    }

    public func create() async -> any SUIFlow<ActiveSessionDIContainer, () -> SignInView> {
        await SignInFlow(di: di, signUpFlowFactory: signUpFlowFactory)
    }
}
