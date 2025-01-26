import AppBase
import ProfileScreen
import SpendingsScreen

@MainActor public protocol HostedAppSession: SharedAppSessionConvertible, AnyObject {
    var sandbox: SandboxAppSession { get }
    var profile: any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions> { get }
    var spendings: any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions> { get }
    func logout() async
}

extension HostedAppSession {
    public var shared: SharedAppSession {
        sandbox.shared
    }
}

@dynamicMemberLookup
public struct AnyHostedAppSession: Equatable, Sendable {
    public static func == (lhs: AnyHostedAppSession, rhs: AnyHostedAppSession) -> Bool {
        lhs.value === rhs.value
    }
    
    public let value: HostedAppSession
    
    public init(value: HostedAppSession) {
        self.value = value
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<HostedAppSession, T>) -> T {
        value[keyPath: keyPath]
    }
}
