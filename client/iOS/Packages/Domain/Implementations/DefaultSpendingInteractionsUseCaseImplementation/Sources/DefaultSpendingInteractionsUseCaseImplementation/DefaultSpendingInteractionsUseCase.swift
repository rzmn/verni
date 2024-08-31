import Domain
import Api
import Foundation
import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultSpendingInteractionsUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultSpendingInteractionsUseCase: SpendingInteractionsUseCase {
    public func create(spending: Spending) async -> Result<Void, CreateSpendingError> {
        do {
            return .success(
                try await api.run(
                    method: Spendings.CreateDeal(
                        deal: DealDto(
                            timestamp: Int64(spending.date.timeIntervalSince1970),
                            details: spending.details,
                            cost: Int64((NSDecimalNumber(decimal: spending.cost).doubleValue * 100)),
                            currency: spending.currency.stringValue,
                            spendings: spending.participants.map {
                                SpendingDto(userId: $0.key, cost: CostDto(cost: $0.value))
                            }
                        )
                    )
                )
            )
        } catch {
            return .failure(CreateSpendingError(apiError: error))
        }
    }
    
    public func delete(spending: Spending.ID) async -> Result<Void, DeleteSpendingError> {
        do {
            return .success(
                try await api.run(method: Spendings.DeleteDeal(dealId: spending))
            )
        } catch {
            return .failure(DeleteSpendingError(apiError: error))
        }
    }
}
