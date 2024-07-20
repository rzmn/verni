import Domain
import Api
import Combine
internal import ApiDomainConvenience

public class DefaultSpendingsRepository {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError> {
        let result = await api.getCounterparties()
        switch result {
        case .success(let previews):
            return .success(previews.map(SpendingsPreview.init))
        case .failure(let apiError):
            return .failure(GeneralError(apiError: apiError))
        }
    }
    
    public func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError> {
        let result = await api.getDeals(counterparty: counterparty)
        switch result {
        case .success(let spendings):
            return .success(spendings.map(IdentifiableSpending.init))
        case .failure(let apiError):
            return .failure(GetSpendingsHistoryError(apiError: apiError))
        }
    }
}
