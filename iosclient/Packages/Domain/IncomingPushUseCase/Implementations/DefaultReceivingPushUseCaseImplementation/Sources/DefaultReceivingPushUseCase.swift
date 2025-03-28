import Entities
import Foundation
import Logging
import UserNotifications
import Api
import IncomingPushUseCase
internal import Convenience

public actor DefaultReceivingPushUseCase {
    public let logger: Logger
    private let hostId: User.Identifier
    private let decoder = JSONDecoder()

    public init(
        hostId: User.Identifier,
        logger: Logger
    ) {
        self.logger = logger
        self.hostId = hostId
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
        let getGroupName = { [hostId] (groupName: String?, groupMembers: [String: String]) -> PushContent.GroupName? in
            if let groupName {
                return .groupName(groupName)
            } else {
                let uidToNameMapping = groupMembers
                    .filter { $0.key != hostId }
                if uidToNameMapping.count == 1, let counterparty = uidToNameMapping.values.first {
                    return .opponentName(counterparty)
                } else {
                    return nil
                }
            }
        }
        switch payload {
        case .spendingCreated(let payload):
            return .spendingCreated(
                .init(
                    spendingName: payload.sn,
                    groupName: getGroupName(payload.gn, payload.pdns.additionalProperties),
                    amount: Amount(dto: payload.a),
                    currency: Currency(dto: payload.c),
                    share: Amount(dto: payload.u)
                )
            )
        case .spendingGroupCreated(let payload):
            return .spendingGroupCreated(
                .init(
                    groupName: getGroupName(payload.gn, payload.pdns.additionalProperties)
                )
            )
        }
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
