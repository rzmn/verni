import Domain
import Api
import Foundation
import PersistentStorage
internal import ApiDomainConvenience

public actor DefaultProfileEditingUseCase {
    private let api: ApiProtocol
    private let persistency: Persistency
    private let repository: ProfileRepository

    public init(api: ApiProtocol, persistency: Persistency, repository: ProfileRepository) {
        self.api = api
        self.persistency = persistency
        self.repository = repository
    }
}

extension DefaultProfileEditingUseCase: ProfileEditingUseCase {
    public func setAvatar(imageData: Data) async throws(SetAvatarError) {
        do {
            try await api.run(
                method: Api.Profile.SetAvatar(dataBase64: imageData.base64EncodedString())
            )
            _ = try? await repository.refreshProfile()
        } catch {
            throw SetAvatarError(apiError: error)
        }
    }

    public func setDisplayName(_ displayName: String) async throws(SetDisplayNameError) {
        do {
            try await api.run(
                method: Api.Profile.SetDisplayName(displayName: displayName)
            )
            _ = try? await repository.refreshProfile()
        } catch {
            throw SetDisplayNameError(apiError: error)
        }
    }

    public func updateEmail(_ email: String) async throws(EmailUpdateError) {
        do {
            let tokens = try await api.run(
                method: Auth.UpdateEmail(email: email)
            )
            Task {
                await persistency.update(refreshToken: tokens.refreshToken)
            }
            _ = try? await repository.refreshProfile()
        } catch {
            throw EmailUpdateError(apiError: error)
        }
    }

    public func updatePassword(old: String, new: String) async throws(PasswordUpdateError) {
        do {
            let tokens = try await api.run(
                method: Auth.UpdatePassword(old: old, new: new)
            )
            Task {
                await persistency.update(refreshToken: tokens.refreshToken)
            }
        } catch {
            throw PasswordUpdateError(apiError: error)
        }
    }
}
