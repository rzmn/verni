import Domain
import Foundation
import Logging
import UserNotifications
internal import Base

public actor DefaultReceivingPushUseCase {
    public let logger: Logger

    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository

    private let decoder = JSONDecoder()

    public init(
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        logger: Logger
    ) {
        self.logger = logger
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
    }
}

extension DefaultReceivingPushUseCase: ReceivingPushUseCase {

    @MainActor public func handle(
        rawPushPayload: [AnyHashable: Any]
    ) async throws(ProcessPushError) -> PushContent {
        let userData: Data
        do {
            userData = try JSONSerialization.data(withJSONObject: rawPushPayload)
        } catch {
            logE { "failed to convert userData into data due error: \(error). userData=\(rawPushPayload)" }
            throw .internalError(InternalError.error("failed to convert userData into data", underlying: error))
        }
        return try await handle(pushData: userData)
    }

    private func handle(pushData: Data) async throws(ProcessPushError) -> PushContent {
        let payload: PushPayload
        do {
            payload = try decoder.decode(Push.self, from: pushData).payload
        } catch {
            logE { "failed to convert push data due error: \(error)" }
            throw .internalError(InternalError.error("failed to convert push data to typed data", underlying: error))
        }
        switch payload {
        case .newExpenseReceived(let payload):
            return try await handle(payload: payload)
        }
    }

    private func handle(
        payload: PushPayload.NewExpenseReceived
    ) async throws(ProcessPushError) -> PushContent {
        Task {
            async let refreshSpendings = try? spendingsRepository.refreshSpendingCounterparties()
            async let refreshHistory = try? spendingsRepository.refreshSpendingsHistory(
                counterparty: payload.authorId
            )
            _ = await [refreshSpendings, refreshHistory] as [any Sendable]
        }
        let spending: Spending
        do {
            spending = try await spendingsRepository.getSpending(id: payload.spendingId)
        } catch {
            logE { "failed to get info error: \(error)" }
            throw .internalError(InternalError.error("failed to get spending info", underlying: error))
        }
        return PushContent(
            title: "newExpenseReceived",
            subtitle: "subtitle!!",
            body: "\(spending.details)"
        )
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
