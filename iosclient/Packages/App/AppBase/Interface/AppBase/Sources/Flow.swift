import SwiftUI

public protocol ScreenProvider<Event, Screen, Args>: Sendable {
    associatedtype Event: Sendable
    associatedtype Args
    associatedtype Screen

    @MainActor func instantiate(
        handler: @MainActor @escaping (Event) -> Void
    ) -> (Args) -> Screen
}

public extension ScreenProvider where Args == Void {
    @MainActor func instantiate(
        handler: @MainActor @escaping (Event) -> Void
    ) -> () -> Screen {
        let value: (Args) -> Screen = instantiate(handler: handler)
        return {
            value(())
        }
    }
}

public extension ScreenProvider where Event == Void {
    @MainActor func instantiate() -> (Args) -> Screen {
        instantiate(handler: { _ in })
    }
}

public extension ScreenProvider where Event == Void, Args == Void {
    @MainActor func instantiate() -> () -> Screen {
        let value: (Args) -> Screen = instantiate()
        return {
            value(())
        }
    }
}
