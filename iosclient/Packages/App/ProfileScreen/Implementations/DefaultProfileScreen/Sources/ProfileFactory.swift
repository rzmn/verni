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
    private let urlProvider: UrlProvider
    private let logger: Logger

    public init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        qrInviteUseCase: QRInviteUseCase,
        urlProvider: UrlProvider,
        logger: Logger
    ) {
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.qrInviteUseCase = qrInviteUseCase
        self.urlProvider = urlProvider
        self.logger = logger
    }
}

extension DefaultProfileFactory: ProfileFactory {
    public func create() async -> any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions> {
        await ProfileModel(
            profileRepository: profileRepository,
            usersRepository: usersRepository,
            qrInviteUseCase: qrInviteUseCase,
            urlProvider: urlProvider,
            logger: logger
        )
    }
}
