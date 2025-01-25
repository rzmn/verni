import AppBase
import AuthWelcomeScreen
import LogInScreen
import DomainLayer

@MainActor public protocol SandboxAppSession: Sendable, AnyObject {
    var auth: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions> { get }
    var logIn: any ScreenProvider<LogInEvent, LogInView, ModalTransition> { get }
    
    func create(domain: HostedDomainLayer) -> HostedAppSession
}

@dynamicMemberLookup
public struct AnySandboxAppSession: Equatable, Sendable {
    public static func == (lhs: AnySandboxAppSession, rhs: AnySandboxAppSession) -> Bool {
        lhs.value === rhs.value
    }
    
    let value: SandboxAppSession
    
    public subscript<T>(dynamicMember keyPath: KeyPath<SandboxAppSession, T>) -> T {
        value[keyPath: keyPath]
    }
}
