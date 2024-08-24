import Domain
import Api
import PersistentStorage
import Combine
import Logging
internal import ApiDomainConvenience
internal import Base

public class DefaultSpendingsRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let longPoll: LongPoll
    private let offline: SpendingsOfflineMutableRepository
    private let counterpartiesSubject = PassthroughSubject<[SpendingsPreview], Never>()
    private var spendingsHistorySubjectById = [User.ID: PassthroughSubject<[IdentifiableSpending], Never>]()

    public init(
        api: ApiProtocol,
        longPoll: LongPoll,
        logger: Logger,
        offline: SpendingsOfflineMutableRepository
    ) {
        self.api = api
        self.longPoll = longPoll
        self.offline = offline
        self.logger = logger
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    private func spendingsHistorySubject(with uid: User.ID) -> PassthroughSubject<[IdentifiableSpending], Never> {
        guard let subject = spendingsHistorySubjectById[uid] else {
            logI { "subject created for \(uid)" }
            let subject = PassthroughSubject<[IdentifiableSpending], Never>()
            spendingsHistorySubjectById[uid] = subject
            return subject
        }
        return subject
    }

    public func spendingCounterpartiesUpdated() async -> AnyPublisher<[SpendingsPreview], Never> {
        await longPoll.poll(for: LongPollCounterpartiesQuery())
            .flatMap { _ in
                Future { [weak self] (promise: @escaping (Result<[SpendingsPreview]?, Never>) -> Void) in
                    guard let self else {
                        return promise(.success(nil))
                    }
                    logI { "got lp [spendingCounterpartiesUpdated], refreshing data" }
                    Task.detached {
                        let result = await self.refreshSpendingCounterparties()
                        switch result {
                        case .success(let counterparties):
                            self.logI { "got lp [spendingCounterpartiesUpdated], refreshing data OK" }
                            promise(.success(counterparties))
                        case .failure(let error):
                            self.logI { "got lp [spendingCounterpartiesUpdated], refreshing data error: \(error), skip" }
                            promise(.success(nil))
                        }
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: counterpartiesSubject)
            .eraseToAnyPublisher()
    }

    public func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<[IdentifiableSpending], Never> {
        await longPoll.poll(for: SpendingsHistoryUpdate(uid: id))
            .flatMap { _ in
                Future { [weak self] (promise: @escaping (Result<[IdentifiableSpending]?, Never>) -> Void) in
                    guard let self else {
                        return promise(.success(nil))
                    }
                    logI { "got lp [spendingsHistoryUpdated, id=\(id)], refreshing data" }
                    Task.detached {
                        let result = await self.refreshSpendingsHistory(counterparty: id)
                        switch result {
                        case .success(let history):
                            self.logI { "got lp [spendingsHistoryUpdated, id=\(id)], refreshing data OK" }
                            promise(.success(history))
                        case .failure(let error):
                            self.logI { "got lp [spendingsHistoryUpdated, id=\(id)], refreshing data error: \(error), skip" }
                            promise(.success(nil))
                        }
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: spendingsHistorySubject(with: id))
            .eraseToAnyPublisher()
    }
    
    public func refreshSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError> {
        logI { "refreshSpendingCounterparties start" }
        switch await api.run(method: Spendings.GetCounterparties()) {
        case .success(let previewsDto):
            let previews = previewsDto.map(SpendingsPreview.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.updateSpendingCounterparties(previews)
            }
            logI { "refreshSpendingCounterparties ok" }
            counterpartiesSubject.send(previews)
            return .success(previews)
        case .failure(let apiError):
            logI { "refreshSpendingCounterparties failed error: \(apiError)" }
            return .failure(GeneralError(apiError: apiError))
        }
    }
    
    public func refreshSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError> {
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] start" }
        let result = await api.run(method: Spendings.GetDeals(counterparty: counterparty))
        switch result {
        case .success(let spendingsDto):
            let spendings = spendingsDto.map(IdentifiableSpending.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.updateSpendingsHistory(counterparty: counterparty, history: spendings)
            }
            logI { "refreshSpendingsHistory[counterparty=\(counterparty)] ok" }
            spendingsHistorySubject(with: counterparty).send(spendings)
            return .success(spendings)
        case .failure(let apiError):
            logI { "refreshSpendingsHistory[counterparty=\(counterparty)] failed error: \(apiError)" }
            return .failure(GetSpendingsHistoryError(apiError: apiError))
        }
    }
}

extension DefaultSpendingsRepository: Loggable {}
