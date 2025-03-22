import AppBase
import Logging

public protocol SignUpFactory<Session>: Sendable {
    associatedtype Session: Sendable
    
    func create() async -> any ScreenProvider<SignUpEvent<Session>, SignUpView<Session>, ModalTransition>
}
