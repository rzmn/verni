import AppBase
import DI

public enum SignUpTerminationEvent: Sendable {
    case canceled
    case created(ActiveSessionDIContainer)
}

@MainActor public protocol SignUpFlowFactory: Sendable {
    func create() async -> any SUIFlow<SignUpTerminationEvent, () -> SignUpView>
}

public class DefaultSignUpFlowFactory: SignUpFlowFactory {
    let di: DIContainer

    public init(di: DIContainer) {
        self.di = di
    }

    public func create() async -> any SUIFlow<SignUpTerminationEvent, () -> SignUpView> {
        await SignUpFlow(di: di)
    }
}
