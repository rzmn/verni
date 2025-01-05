import Domain
import Api
import Foundation
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
                    deal: ExpenseDto(
                        domain: spending
                    )
                )
            )
        } catch {
            throw CreateSpendingError(apiError: error)
        }
    }

    public func delete(spending: Spending.Identifier) async throws(DeleteSpendingError) {
        do {
            try await api.run(method: Spendings.DeleteDeal(dealId: spending))
        } catch {
            throw DeleteSpendingError(apiError: error)
        }
    }
}
