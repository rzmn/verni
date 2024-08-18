import Domain
import Api
import PersistentStorage
import Combine
internal import ApiDomainConvenience

public class DefaultSpendingsRepository {
    private let api: ApiProtocol
    private let offline: SpendingsOfflineMutableRepository

    public init(api: ApiProtocol, offline: SpendingsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError> {
        switch await api.run(method: Spendings.GetCounterparties()) {
        case .success(let previewsDto):
            let previews = previewsDto.map(SpendingsPreview.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.updateSpendingCounterparties(previews)
            }
            return .success(previews)
        case .failure(let apiError):
            return .failure(GeneralError(apiError: apiError))
        }
    }
    
    public func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError> {
        let result = await api.run(method: Spendings.GetDeals(counterparty: counterparty))
        switch result {
        case .success(let spendingsDto):
            let spendings = spendingsDto.map(IdentifiableSpending.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.updateSpendingsHistory(counterparty: counterparty, history: spendings)
            }
            return .success(spendings)
        case .failure(let apiError):
            return .failure(GetSpendingsHistoryError(apiError: apiError))
        }
    }

    public var spendingCounterpartiesUpdated: AnyPublisher<Void, Never> {
        api.eventQueue
            .compactMap { event -> Void? in
                guard case .spendingCounterpartiesUpdated = event else {
                    return nil
                }
                return ()
            }
            .eraseToAnyPublisher()
    }

    public var spendingsHistoryUpdated: AnyPublisher<User.ID, Never> {
        api.eventQueue
            .compactMap { event -> User.ID? in
                guard case .spendingsHistoryUpdated(let id) = event else {
                    return nil
                }
                return id
            }
            .eraseToAnyPublisher()
    }
}
