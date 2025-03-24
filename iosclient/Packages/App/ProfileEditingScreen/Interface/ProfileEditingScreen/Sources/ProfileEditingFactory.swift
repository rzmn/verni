import AppBase

public protocol ProfileEditingFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEditingEvent, ProfileEditingView, ProfileEditingTransitions>
}
