import AppBase

public protocol AuthWelcomeFactory: Sendable {
    func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions>
}
