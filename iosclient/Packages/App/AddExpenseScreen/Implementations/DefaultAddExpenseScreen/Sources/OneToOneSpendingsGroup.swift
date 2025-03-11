import Entities

struct OneToOneSpendingsGroup: Sendable, Equatable {
    let counterparty: User
    let group: SpendingGroup
}
