import SwiftUI

public protocol ScreenProvider<Event, Screen>: Sendable {
    associatedtype Event: Sendable
    associatedtype Screen

    @MainActor func instantiate(
        handler: @MainActor @escaping (Event) -> Void
    ) -> Screen
}
