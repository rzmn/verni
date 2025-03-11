import AppBase

public protocol UserPreviewFactory: Sendable {
    func create() async -> any ScreenProvider<UserPreviewEvent, UserPreviewView, UserPreviewTransitions>
}
