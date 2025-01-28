import EmailConfirmationUseCase
import Api
import Entities
internal import EntitiesApiConvenience

extension SendEmailConfirmationCodeError {
    public init(error: Components.Schemas._Error) {
        switch error.reason {
        default:
            self = .other(GeneralError(error: error))
        }
    }
    
    public init(error: Error) {
        self = .other(GeneralError(error: error))
    }
}

