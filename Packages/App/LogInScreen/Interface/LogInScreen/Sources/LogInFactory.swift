import AppBase
import Logging

public protocol LogInFactory: Sendable {
    func create() async -> any ScreenProvider<LogInEvent, LogInView, ModalTransition>
}
