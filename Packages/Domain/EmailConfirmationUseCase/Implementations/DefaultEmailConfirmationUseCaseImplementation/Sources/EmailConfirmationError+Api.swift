import EmailConfirmationUseCase
import Api
import Entities
internal import EntitiesApiConvenience

extension EmailConfirmationError {
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

