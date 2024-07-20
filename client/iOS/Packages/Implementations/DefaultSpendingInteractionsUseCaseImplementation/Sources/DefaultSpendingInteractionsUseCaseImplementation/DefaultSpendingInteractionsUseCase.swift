import Domain
import Api
import Combine
import Foundation
internal import ApiDomainConvenience

public class DefaultSpendingInteractionsUseCase {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

extension DefaultSpendingInteractionsUseCase: SpendingInteractionsUseCase {
    public func create(spending: Spending) async -> Result<[SpendingsPreview], CreateSpendingError> {
        let result = await api.createDeal(
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
        switch result {
        case .success(let previews):
            return .success(previews.map(SpendingsPreview.init))
        case .failure(let apiError):
            return .failure(CreateSpendingError(apiError: apiError))
        }
    }
    
    public func delete(spending: Spending.ID) async -> Result<[SpendingsPreview], DeleteSpendingError> {
        let result = await api.deleteDeal(id: spending)
        switch result {
        case .success(let previews):
            return .success(previews.map(SpendingsPreview.init))
        case .failure(let apiError):
            return .failure(DeleteSpendingError(apiError: apiError))
        }
    }
}
