import Domain
import Api
import Foundation
import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultSpendingInteractionsUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultSpendingInteractionsUseCase: SpendingInteractionsUseCase {
    public func create(spending: Spending) async throws(CreateSpendingError) {
        do {
            try await api.run(
                method: Spendings.CreateDeal(
                    deal: DealDto(
                        domain: spending
                    )
                )
            )
        } catch {
            throw CreateSpendingError(apiError: error)
        }
    }

    public func delete(spending: Spending.ID) async throws(DeleteSpendingError) {
        do {
            try await api.run(method: Spendings.DeleteDeal(dealId: spending))
        } catch {
            throw DeleteSpendingError(apiError: error)
        }
    }
}
