import AppBase
import DebugMenuScreen
import SplashScreen

@MainActor public protocol SharedAppSession: AnyObject, SharedAppSessionConvertible {
    var splash: any ScreenProvider<Void, SplashView, ModalTransition> { get }
    var debug: any ScreenProvider<DebugMenuEvent, DebugMenuView, Void> { get }
}

extension SharedAppSession {
    public var shared: SharedAppSession {
        self
    }
}

@MainActor public protocol SharedAppSessionConvertible: Sendable {
    var shared: SharedAppSession { get }
}

@dynamicMemberLookup
public struct AnySharedAppSession: Equatable, Sendable {
    public static func == (lhs: AnySharedAppSession, rhs: AnySharedAppSession) -> Bool {
        lhs.value === rhs.value
    }

    public let value: SharedAppSession
    
    public init(value: SharedAppSession) {
        self.value = value
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<SharedAppSession, T>) -> T {
        value[keyPath: keyPath]
    }
}
