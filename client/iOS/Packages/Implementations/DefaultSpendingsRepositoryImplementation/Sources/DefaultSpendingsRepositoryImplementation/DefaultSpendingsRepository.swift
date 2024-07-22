import Domain
import Api
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultSpendingsRepository {
    private let api: Api
    private let persistency: Persistency

    public init(api: Api, persistency: Persistency) {
        self.api = api
        self.persistency = persistency
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError> {
        let result = await api.getCounterparties()
        switch result {
        case .success(let previewsDto):
            let previews = previewsDto.map(SpendingsPreview.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await persistency.updateSpendingCounterparties(previews)
            }
            return .success(previews)
        case .failure(let apiError):
            return .failure(GeneralError(apiError: apiError))
        }
    }
    
    public func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError> {
        let result = await api.getDeals(counterparty: counterparty)
        switch result {
        case .success(let spendingsDto):
            let spendings = spendingsDto.map(IdentifiableSpending.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await persistency.updateSpendingsHistory(counterparty: counterparty, history: spendings)
            }
            return .success(spendings)
        case .failure(let apiError):
            return .failure(GetSpendingsHistoryError(apiError: apiError))
        }
    }

    public var spendingsUpdated: AsyncStream<Void> {
        api.spendingsUpdated
    }
}
