import Domain
import Api
import Foundation
import PersistentStorage
import Base
import AsyncExtensions
internal import ApiDomainConvenience

public actor DefaultProfileEditingUseCase {
    private let api: ApiProtocol
    private let persistency: Persistency
    private let profile: ExternallyUpdatable<Domain.Profile>
    private let taskFactory: TaskFactory
    private let avatarsRepository: AvatarsOfflineMutableRepository

    public init(
        api: ApiProtocol,
        persistency: Persistency,
        taskFactory: TaskFactory,
        avatarsRepository: AvatarsOfflineMutableRepository,
        profile: ExternallyUpdatable<Domain.Profile>
    ) {
        self.api = api
        self.persistency = persistency
        self.taskFactory = taskFactory
        self.avatarsRepository = avatarsRepository
        self.profile = profile
    }
}

extension DefaultProfileEditingUseCase: ProfileEditingUseCase {
    public func setAvatar(imageData: Data) async throws(SetAvatarError) {
        do {
            let id = try await api.run(
                method: Api.Profile.SetAvatar(dataBase64: imageData.base64EncodedString())
            )
            await avatarsRepository.store(data: imageData, for: id)
            await profile.add { profile in
                Profile(profile, user: User(profile.user, avatar: Avatar(id: id)))
            }
        } catch {
            throw SetAvatarError(apiError: error)
        }
    }

    public func setDisplayName(_ displayName: String) async throws(SetDisplayNameError) {
        do {
            try await api.run(
                method: Api.Profile.SetDisplayName(displayName: displayName)
            )
            await profile.add { profile in
                Profile(profile, user: User(profile.user, displayName: displayName))
            }
        } catch {
            throw SetDisplayNameError(apiError: error)
        }
    }

    public func updateEmail(_ email: String) async throws(EmailUpdateError) {
        do {
            let tokens = try await api.run(
                method: Auth.UpdateEmail(email: email)
            )
            await persistency.update(refreshToken: tokens.refreshToken)
            await profile.add { profile in
                Profile(profile, email: email, isEmailVerified: false)
            }
        } catch {
            throw EmailUpdateError(apiError: error)
        }
    }

    public func updatePassword(old: String, new: String) async throws(PasswordUpdateError) {
        do {
            let tokens = try await api.run(
                method: Auth.UpdatePassword(old: old, new: new)
            )
            await persistency.update(refreshToken: tokens.refreshToken)
        } catch {
            throw PasswordUpdateError(apiError: error)
        }
    }
}
