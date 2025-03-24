import AppBase
import ProfileEditingScreen
import ProfileRepository
import UsersRepository
import AvatarsRepository
import Logging

public final class DefaultProfileEditingFactory {
    private let profileRepository: ProfileRepository
    private let usersRepository: UsersRepository
    private let avatarsRepository: AvatarsRepository
    private let logger: Logger

    public init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        avatarsRepository: AvatarsRepository,
        logger: Logger
    ) {
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.avatarsRepository = avatarsRepository
        self.logger = logger
    }
}

extension DefaultProfileEditingFactory: ProfileEditingFactory {
    public func create() async -> any ScreenProvider<ProfileEditingEvent, ProfileEditingView, ProfileEditingTransitions> {
        await ProfileEditingModel(
            profileRepository: profileRepository,
            usersRepository: usersRepository,
            avatarsRepository: avatarsRepository,
            logger: logger
        )
    }
}
