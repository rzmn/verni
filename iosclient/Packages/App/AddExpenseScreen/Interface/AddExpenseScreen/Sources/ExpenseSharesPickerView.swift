import SwiftUI
import AppBase
import Entities
internal import DesignSystem

struct ExpenseSharesPickerView: View {
    @ObservedObject private var store: Store<AddExpenseState, AddExpenseAction>
    @Environment(AvatarView.Repository.self) private var repository
    @Environment(ColorPalette.self) private var colors
    private let host: User
    private let counterparty: User
    
    init(
        store: Store<AddExpenseState, AddExpenseAction>,
        host: User,
        counterparty: User
    ) {
        self.store = store
        self.host = host
        self.counterparty = counterparty
    }

    var body: some View {
        VStack {
            item(paid: host, owed: counterparty, selected: store.state.paidByHost)
                .padding(2)
            item(paid: counterparty, owed: host, selected: !store.state.paidByHost)
                .padding(2)
        }
        .background(colors.background.secondary.default)
        .clipShape(.rect(cornerRadius: 18, style: .circular))
    }
    
    @ViewBuilder private func item(paid: User, owed: User, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    AvatarView(avatar: paid.payload.avatar)
                        .frame(width: 28, height: 28)
                        .clipShape(.circle)
                    Image.arrowRight
                        .foregroundStyle(colors.icon.primary.default)
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, 4)
                    AvatarView(avatar: owed.payload.avatar)
                        .frame(width: 28, height: 28)
                        .clipShape(.circle)
                    Spacer()
                }
                Text({
                    let argumentString = counterparty.payload.displayName
                    let formatString: String = paid.id == host.id ? .addExpenseYouOweFormat : .addExpenseOwesYouFormat
                    let resultString = String(format: formatString, argumentString)
                    
                    var result = AttributedString(resultString)
                    result.font = .medium(size: 15)
                    result.foregroundColor = colors.text.secondary.default
                    
                    if let placeholderRange = formatString.range(of: "%@") {
                        let startOffset = formatString.distance(from: formatString.startIndex, to: placeholderRange.lowerBound)
                        let startIndex = result.index(result.startIndex, offsetByCharacters: startOffset)
                        let endIndex = result.index(startIndex, offsetByCharacters: argumentString.count)
                        result[startIndex..<endIndex].font = .bold(size: 15)
                        result[startIndex..<endIndex].foregroundColor = colors.text.brand.static
                    }
                    
                    return result
                }())
            }
            .padding([.top, .leading], 15)
            Spacer()
            HStack {
                var amount: Amount {
                    switch store.state.splitRule {
                    case .equally:
                        store.state.amount / 2
                    case .full:
                        store.state.amount
                    }
                }
                BalanceAccessory(
                    style: paid.id == host.id ? .positive : .negative
                )
                Text(store.state.currency.formatted(amount: amount))
                    .font(.medium(size: 20))
                    .foregroundStyle(colors.text.primary.default)
            }
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(colors.background.primary.default)
            .clipShape(.rect(cornerRadius: 24, style: .circular))
            .padding(.trailing, 8)
        }
        .frame(height: 82)
        .background(
            selected
                ? colors.background.primary.default
                : .clear
        )
        .opacity(selected ? 1 : 0.5)
        .clipShape(.rect(cornerRadius: 16, style: .circular))
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

extension User {
    static var previewHost: User {
        User(
            id: "host",
            payload: UserPayload(
                displayName: "host",
                avatar: "123"
            )
        )
    }
    
    static var previewCounterparty: User {
        User(
            id: "counterparty",
            payload: UserPayload(
                displayName: "counterparty",
                avatar: "456"
            )
        )
    }
}

#Preview {
    ExpenseSharesPickerView(
        store: Store(
            state: AddExpenseState(
                currency: .russianRuble,
                amount: 123,
                splitRule: .equally,
                paidByHost: true,
                title: "expense",
                host: .previewHost,
                counterparty: .previewCounterparty,
                availableCounterparties: []
            ),
            reducer: { state, _ in state }
        ),
        host: .previewHost,
        counterparty: .previewCounterparty
    )
    .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
