import AppBase
import ProfileScreen
import ProfileRepository
import UsersRepository
import QrInviteUseCase
import Logging

public final class DefaultProfileFactory {
    private let profileRepository: @Sendable () async -> ProfileRepository
    private let usersRepository: @Sendable () async -> UsersRepository
    private let qrInviteUseCase: @Sendable () async -> QRInviteUseCase
    private let logger: Logger

    public init(
        profileRepository: @Sendable @escaping () async -> ProfileRepository,
        usersRepository: @Sendable @escaping () async -> UsersRepository,
        qrInviteUseCase: @Sendable @escaping () async -> QRInviteUseCase,
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
            profileRepository: await profileRepository(),
            usersRepository: await usersRepository(),
            qrInviteUseCase: await qrInviteUseCase(),
            logger: logger
        )
    }
}
