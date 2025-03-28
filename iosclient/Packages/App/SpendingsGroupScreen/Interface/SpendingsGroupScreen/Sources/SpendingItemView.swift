import SwiftUI
import AppBase
import Entities
internal import DesignSystem

struct SpendingItemView: View {
    @Environment(ColorPalette.self) var colors
    let store: Store<SpendingsGroupState, SpendingsGroupAction>
    private let item: SpendingsGroupState.Item
    private let counterparty: String?
    
    init(
        store: Store<SpendingsGroupState, SpendingsGroupAction>,
        item: SpendingsGroupState.Item,
        counterparty: String?
    ) {
        self.store = store
        self.item = item
        self.counterparty = counterparty
    }
    
    var body: some View {
        HStack(spacing: 0) {
            spendingItemPreview
                .padding(.leading, 16)
            Spacer()
            spendingDiffPreview
                .padding(.trailing, 16)

        }
        .frame(height: 76)
        .background(colors.background.primary.default)
        .clipShape(.rect(cornerRadius: 24))
    }
    
    private var spendingItemPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(item.name)
                .font(.medium(size: 18))
                .foregroundStyle(colors.text.primary.default)
            if let whoOwsString {
                Text(whoOwsString)
                    .font(.medium(size: 13))
                    .foregroundStyle(colors.text.primary.default)
            }
            Text(item.createdAt)
                .font(.medium(size: 13))
                .foregroundStyle(colors.text.secondary.default)
            Spacer()
        }
    }
    
    private var whoOwsString: String? {
        guard let counterparty else {
            return nil
        }
        if item.diff > 0 {
            return .spending(
                paidBy: .you,
                amount: item.currency.formatted(amount: item.amount)
            )
        } else {
            return .spending(
                paidBy: counterparty,
                amount: item.currency.formatted(amount: item.amount)
            )
        }
    }
    
    private var spendingDiffPreview: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
            Text(accessoryText)
                .foregroundStyle(colors.text.secondary.default)
                .font(.medium(size: 15))
            HStack {
                BalanceAccessory(
                    style: {
                        if item.diff >= 0 {
                            return .positive
                        } else {
                            return .negative
                        }
                    }()
                )
                Text(item.diffFormatted)
                    .font(.medium(size: 20))
                    .foregroundStyle(colors.text.primary.default)
                    .contentTransition(.numericText())
                    .animation(.default, value: item.amountFormatted)
            }
            .padding(.top, 2)
            .padding(.bottom, 12)
        }
    }
    
    private var accessoryText: LocalizedStringKey {
        if item.diff >= 0 {
            return .spendingsPositiveBalance
        } else {
            return .spendingsNegativeBalance
        }
    }
}

#if DEBUG

extension SpendingsGroupState.Item {
    static var preview: Self {
        .init(
            id: "la poste",
            name: "la poste",
            currency: .euro,
            createdAt: "12 oct",
            amount: 4,
            diff: 2
        )
    }
}

#Preview {
    SpendingItemView(
        store: Store(
            state: .init(
                preview: SpendingsGroupState.GroupPreview(
                    image: "123",
                    name: "group name",
                    balance: [:]
                ),
                items: [
                    .preview
                ]
            ),
            reducer: { state, _ in state }
        ),
        item: .preview,
        counterparty: nil
    )
    .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
