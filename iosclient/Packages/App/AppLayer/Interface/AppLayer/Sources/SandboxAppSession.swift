import AppBase
import AuthWelcomeScreen
import LogInScreen
import SignUpScreen
import DomainLayer

@MainActor public protocol SandboxAppSession: SharedAppSessionConvertible, AnyObject {
    var auth: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions> { get }
    var logIn: any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition> { get }
    var signUp: any ScreenProvider<SignUpEvent<AnyHostedAppSession>, SignUpView<AnyHostedAppSession>, ModalTransition> { get }
}

@dynamicMemberLookup
public struct AnySandboxAppSession: Equatable, Sendable {
    public static func == (lhs: AnySandboxAppSession, rhs: AnySandboxAppSession) -> Bool {
        lhs.value === rhs.value
    }
    
    public let value: SandboxAppSession
    
    public init(value: SandboxAppSession) {
        self.value = value
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<SandboxAppSession, T>) -> T {
        value[keyPath: keyPath]
    }
}
