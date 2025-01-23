import AppBase

public protocol ProfileFactory: Sendable {
    func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
}
