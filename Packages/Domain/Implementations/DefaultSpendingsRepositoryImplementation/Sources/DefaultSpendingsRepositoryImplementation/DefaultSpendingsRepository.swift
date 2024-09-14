import Domain
import Api
import PersistentStorage
import Combine
import Logging
import Base
internal import ApiDomainConvenience

public actor DefaultSpendingsRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let longPoll: LongPoll
    private let offline: SpendingsOfflineMutableRepository
    private let counterpartiesSubject = PassthroughSubject<[SpendingsPreview], Never>()
    private let taskFactory: TaskFactory
    private var spendingsHistorySubjectById = [User.ID: PassthroughSubject<[IdentifiableSpending], Never>]()

    public init(
        api: ApiProtocol,
        longPoll: LongPoll,
        logger: Logger,
        offline: SpendingsOfflineMutableRepository,
        taskFactory: TaskFactory
    ) {
        self.api = api
        self.longPoll = longPoll
        self.offline = offline
        self.logger = logger
        self.taskFactory = taskFactory
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpending(id: Spending.ID) async throws(GetSpendingError) -> Spending {
        logI { "getSpending[id=\(id)] start" }
        let result: Spending
        do {
            result = Spending(dto: try await api.run(method: Spendings.GetDeal(dealId: id)))
        } catch {
            logI { "getSpending[id=\(id)] failed error: \(error)" }
            throw GetSpendingError(apiError: error)
        }
        return result
    }

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
        let sendablePromise: @Sendable (@Sendable @escaping (Result<[SpendingsPreview]?, Never>) -> Void) -> Void = { promise in
            self.logI { "got lp [spendingCounterpartiesUpdated], refreshing data" }
            self.taskFactory.task {
                let result = try? await self.refreshSpendingCounterparties()
                promise(.success(result))
            }
        }
        return await longPoll.poll(for: LongPollCounterpartiesQuery())
            .flatMap { _ in
                Future { [sendablePromise] promise in
                    // https://forums.swift.org/t/await-non-sendable-callback-violates-actor-isolation/69354
                    nonisolated(unsafe) let promise = promise
                    sendablePromise {
                        promise($0)
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: counterpartiesSubject)
            .eraseToAnyPublisher()
    }

    public func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<[IdentifiableSpending], Never> {
        let sendablePromise: @Sendable (@Sendable @escaping (Result<[IdentifiableSpending]?, Never>) -> Void) -> Void = { promise in
            self.logI { "got lp spendingsHistoryUpdated[counterparty=\(id)], refreshing data" }
            self.taskFactory.task {
                let result = try? await self.refreshSpendingsHistory(counterparty: id)
                promise(.success(result))
            }
        }
        return await longPoll.poll(for: LongPollSpendingsHistoryQuery(uid: id))
            .flatMap { _ in
                Future { [sendablePromise] promise in
                    // https://forums.swift.org/t/await-non-sendable-callback-violates-actor-isolation/69354
                    nonisolated(unsafe) let promise = promise
                    sendablePromise {
                        promise($0)
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: spendingsHistorySubject(with: id))
            .eraseToAnyPublisher()
    }

    public func refreshSpendingCounterparties() async throws(GeneralError) -> [SpendingsPreview] {
        logI { "refreshSpendingCounterparties start" }
        let counterparties: [SpendingsPreview]
        do {
            counterparties = try await api.run(method: Spendings.GetCounterparties()).map(SpendingsPreview.init)
        } catch {
            logI { "refreshSpendingCounterparties failed error: \(error)" }
            throw GeneralError(apiError: error)
        }
        taskFactory.detached {
            await self.offline.updateSpendingCounterparties(counterparties)
        }
        logI { "refreshSpendingCounterparties ok" }
        counterpartiesSubject.send(counterparties)
        return counterparties
    }

    public func refreshSpendingsHistory(counterparty: User.ID) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending] {
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] start" }
        let spendings: [IdentifiableSpending]
        do {
            spendings = try await api.run(method: Spendings.GetDeals(counterparty: counterparty)).map(IdentifiableSpending.init)
        } catch {
            logI { "refreshSpendingsHistory[counterparty=\(counterparty)] failed error: \(error)" }
            throw GetSpendingsHistoryError(apiError: error)
        }
        taskFactory.detached {
            await self.offline.updateSpendingsHistory(counterparty: counterparty, history: spendings)
        }
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] ok" }
        spendingsHistorySubject(with: counterparty).send(spendings)
        return spendings
    }
}

extension DefaultSpendingsRepository: Loggable {}
