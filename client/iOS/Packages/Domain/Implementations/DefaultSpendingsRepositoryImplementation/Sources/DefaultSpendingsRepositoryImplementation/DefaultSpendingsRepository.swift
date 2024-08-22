import Domain
import Api
import PersistentStorage
import Combine
internal import ApiDomainConvenience
internal import Base

public class DefaultSpendingsRepository {
    private let api: ApiProtocol
    private let longPoll: LongPoll
    private let offline: SpendingsOfflineMutableRepository

    private var spendingsHistoryUpdatedById = [User.ID: AnyPublisher<Void, Never>]()
    private var spendingCounterpartiesSubscribersCountById = [User.ID: Int]()

    public init(api: ApiProtocol, longPoll: LongPoll, offline: SpendingsOfflineMutableRepository) {
        self.api = api
        self.longPoll = longPoll
        self.offline = offline
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func spendingCounterpartiesUpdated() async -> AnyPublisher<Void, Never> {
        await longPoll.poll(for: LongPollCounterpartiesQuery())
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<Void, Never> {
        await longPoll.poll(for: SpendingsHistoryUpdate(uid: id))
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
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
}
