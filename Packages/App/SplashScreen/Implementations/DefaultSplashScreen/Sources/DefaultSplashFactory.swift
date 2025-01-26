import AppBase
import SplashScreen

@MainActor public final class DefaultSplashFactory {
    public init() {}
}

extension DefaultSplashFactory: SplashFactory {
    public func instantiate(handler: @escaping @MainActor (Event) -> Void) -> (ModalTransition) -> SplashView {
        return { transition in
            SplashView(transition: transition)
        }
    }
}

extension DefaultSplashFactory: ScreenProvider {
    public typealias Event = Void
    
    public func create() -> any ScreenProvider<Event, SplashView, ModalTransition> {
        self
    }
}
