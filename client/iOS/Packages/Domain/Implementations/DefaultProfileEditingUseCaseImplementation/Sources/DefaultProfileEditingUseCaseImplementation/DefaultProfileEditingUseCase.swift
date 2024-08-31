import Domain
import Api
import Foundation
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultProfileEditingUseCase {
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
    public func setAvatar(imageData: Data) async -> Result<Void, Domain.SetAvatarError> {
        do {
            try await api.run(
                method: Api.Profile.SetAvatar(dataBase64: imageData.base64EncodedString())
            )
            await repository.refreshProfile()
            return .success(())
        } catch {
            return .failure(SetAvatarError(apiError: error))
        }
    }
    
    public func setDisplayName(_ displayName: String) async -> Result<Void, Domain.SetDisplayNameError> {
        do {
            try await api.run(
                method: Api.Profile.SetDisplayName(displayName: displayName)
            )
            await repository.refreshProfile()
            return .success(())
        } catch {
            return .failure(SetDisplayNameError(apiError: error))
        }
    }
    
    public func updateEmail(_ email: String) async -> Result<Void, EmailUpdateError> {
        do {
            let tokens = try await api.run(
                method: Auth.UpdateEmail(email: email)
            )
            Task.detached {
                await self.persistency.update(refreshToken: tokens.refreshToken)
            }
            await repository.refreshProfile()
            return .success(())
        } catch {
            return .failure(EmailUpdateError(apiError: error))
        }
    }

    public func updatePassword(old: String, new: String) async -> Result<Void, PasswordUpdateError> {
        do {
            let tokens = try await api.run(
                method: Auth.UpdatePassword(old: old, new: new)
            )
            Task.detached {
                await self.persistency.update(refreshToken: tokens.refreshToken)
            }
            return .success(())
        } catch {
            return .failure(PasswordUpdateError(apiError: error))
        }
    }
}
