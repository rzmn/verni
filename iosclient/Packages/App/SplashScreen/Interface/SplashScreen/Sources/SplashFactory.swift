import AppBase

public protocol SplashFactory: Sendable {
    func create() async -> any ScreenProvider<Void, SplashView, ModalTransition>
}
