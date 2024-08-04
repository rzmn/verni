import Domain
import Api
import Foundation
internal import ApiDomainConvenience

public class DefaultProfileEditingUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultProfileEditingUseCase: ProfileEditingUseCase {
    public func setAvatar(imageData: Data) async -> Result<Void, Domain.SetAvatarError> {
        let method = Api.Profile.SetAvatar(dataBase64: imageData.base64EncodedString())
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(SetAvatarError(apiError: apiError))
        }
    }
    
    public func setDisplayName(_ displayName: String) async -> Result<Void, Domain.SetDisplayNameError> {
        let method = Api.Profile.SetDisplayName(displayName: displayName)
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(SetDisplayNameError(apiError: apiError))
        }
    }
    
    public func updateEmail(_ email: String) async -> Result<Void, EmailUpdateError> {
        let method = Auth.UpdateEmail(email: email)
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(EmailUpdateError(apiError: apiError))
        }
    }

    public func updatePassword(old: String, new: String) async -> Result<Void, PasswordUpdateError> {
        let method = Auth.UpdatePassword(old: old, new: new)
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(PasswordUpdateError(apiError: apiError))
        }
    }
}
