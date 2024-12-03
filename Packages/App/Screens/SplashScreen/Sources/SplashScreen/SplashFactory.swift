import AppBase
import DI

public protocol SplashFactory: Sendable {
    func create() async -> any ScreenProvider<Void, SplashView, BottomSheetTransition>
}

public final class DefaultSplashFactory: SplashFactory, ScreenProvider {
    public typealias Event = Void

    public init() {}

    public func create() async -> any ScreenProvider<Event, SplashView, BottomSheetTransition> {
        self
    }
    
    public func instantiate(handler: @escaping @MainActor (Event) -> Void) -> (BottomSheetTransition) -> SplashView {
        return { transition in
            SplashView(transition: transition)
        }
    }
    
}

