import AppBase
import Logging

public protocol LogInFactory<Session>: Sendable {
    associatedtype Session: Sendable
    
    func create() async -> any ScreenProvider<LogInEvent<Session>, LogInView<Session>, ModalTransition>
}
