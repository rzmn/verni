import AppBase
import ProfileScreen
import ProfileRepository
import UsersRepository
import QrInviteUseCase
import Logging

public final class DefaultProfileFactory {
    private let profileRepository: ProfileRepository
    private let usersRepository: UsersRepository
    private let qrInviteUseCase: QRInviteUseCase
    private let logger: Logger

    public init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        qrInviteUseCase: QRInviteUseCase,
        logger: Logger
    ) {
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.qrInviteUseCase = qrInviteUseCase
        self.logger = logger
    }
}

extension DefaultProfileFactory: ProfileFactory {
    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions> {
        await ProfileModel(
            profileRepository: profileRepository,
            usersRepository: usersRepository,
            qrInviteUseCase: qrInviteUseCase,
            logger: logger
        )
    }
}
