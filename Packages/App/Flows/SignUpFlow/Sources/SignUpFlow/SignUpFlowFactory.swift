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
    let haptic: HapticManager

    public init(di: DIContainer, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any SUIFlow<SignUpTerminationEvent, () -> SignUpView> {
        await SignUpFlow(di: di, haptic: haptic)
    }
}
