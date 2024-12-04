import AppBase
import DI

public protocol SplashFactory: Sendable {
    func create() async -> any ScreenProvider<Void, SplashView, ModalTransition>
}

public final class DefaultSplashFactory: SplashFactory, ScreenProvider {
    public typealias Event = Void

    public init() {}

    public func create() async -> any ScreenProvider<Event, SplashView, ModalTransition> {
        self
    }
    
    public func instantiate(handler: @escaping @MainActor (Event) -> Void) -> (ModalTransition) -> SplashView {
        return { transition in
            SplashView(transition: transition)
        }
    }
    
}

