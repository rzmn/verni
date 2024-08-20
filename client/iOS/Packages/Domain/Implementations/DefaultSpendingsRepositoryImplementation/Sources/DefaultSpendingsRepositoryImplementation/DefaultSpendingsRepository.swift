import Domain
import Api
import PersistentStorage
import Combine
internal import ApiDomainConvenience
internal import Base

public class DefaultSpendingsRepository {
    private let api: ApiProtocol
    private let offline: SpendingsOfflineMutableRepository

    public lazy var spendingCounterpartiesUpdated = createSpendingCounterpartiesUpdatedSubject()
    private var spendingCounterpartiesSubscribersCount = 0

    private var spendingsHistoryUpdatedById = [User.ID: AnyPublisher<Void, Never>]()
    private var spendingCounterpartiesSubscribersCountById = [User.ID: Int]()

    public init(api: ApiProtocol, offline: SpendingsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
    }
}

extension DefaultSpendingsRepository {
    private func createSpendingCounterpartiesUpdatedSubject() -> AnyPublisher<Void, Never> {
        PassthroughSubject<Void, Never>()
            .handleEvents(
                receiveSubscription: weak(self, type(of: self).spendingCounterpartiesSubscribed) • nop,
                receiveCompletion: weak(self, type(of: self).spendingCounterpartiesUnsubscribed) • nop,
                receiveCancel: weak(self, type(of: self).spendingCounterpartiesUnsubscribed)
            )
            .eraseToAnyPublisher()
    }

    private func spendingCounterpartiesSubscribed() {
        spendingCounterpartiesSubscribersCount += 1
    }

    private func spendingCounterpartiesUnsubscribed() {
        spendingCounterpartiesSubscribersCount -= 1
    }

    public func spendingsHistoryUpdated(for id: User.ID) -> AnyPublisher<Void, Never> {
        if let publisher = spendingsHistoryUpdatedById[id] {
            return publisher
        }
        let publisher = PassthroughSubject<Void, Never>()
            .handleEvents(
                receiveSubscription: curry(weak(self, type(of: self).spendingsHistorySubscribed))(id) • nop,
                receiveCompletion: curry(weak(self, type(of: self).spendingsHistoryUnsubscribed))(id) • nop,
                receiveCancel: curry(weak(self, type(of: self).spendingsHistoryUnsubscribed))(id)
            )
            .eraseToAnyPublisher()
        spendingsHistoryUpdatedById[id] = publisher
        return publisher
    }

    private func spendingsHistorySubscribed(for id: User.ID) {

    }

    private func spendingsHistoryUnsubscribed(for id: User.ID) {

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
}
