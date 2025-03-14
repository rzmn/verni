import SwiftUI
import AppBase
import Entities
internal import DesignSystem
internal import Convenience

struct CounterpartiesPickerView: View {
    @ObservedObject private var store: Store<AddExpenseState, AddExpenseAction>
    @Environment(AvatarView.Repository.self) private var repository
    @Environment(ColorPalette.self) private var colors
    
    init(store: Store<AddExpenseState, AddExpenseAction>) {
        self.store = store
    }
    
    var body: some View {
        content
            .frame(height: 54)
    }
    
    @ViewBuilder private var content: some View {
        if let picked = store.state.counterparty {
            HStack {
                Spacer()
                    .frame(width: 5)
                AvatarView(avatar: picked.payload.avatar)
                    .frame(width: 38, height: 38)
                    .clipShape(.rect(cornerRadius: 19))
                Text(picked.payload.displayName)
                    .foregroundStyle(colors.text.primary.default)
                    .font(.medium(size: 15))
                Spacer()
                Image.pencilBorder
                    .foregroundStyle(colors.icon.secondary.default)
                    .onTapGesture {
                        withAnimation(.default.speed(3)) {
                            store.dispatch(.selectCounterparty(nil))
                        }
                    }
                Spacer()
                    .frame(width: 16)
            }
            .frame(maxHeight: .infinity)
            .background(colors.background.secondary.default)
            .clipShape(.rect(cornerRadius: 16))
        } else {
            HStack {
                ForEach(
                    store.state.availableCounterparties.map {
                        AnyIdentifiable(value: $0, id: $0.id)
                    }
                ) { item in
                    AvatarView(avatar: item.value.payload.avatar)
                        .background(colors.background.secondary.default)
                        .frame(width: 38, height: 38)
                        .clipShape(.rect(cornerRadius: 19))
                        .padding(.leading, 5)
                        .onTapGesture {
                            withAnimation(.default.speed(3)) {
                                store.dispatch(.selectCounterparty(item.id))
                            }
                        }
                }
                Spacer()
            }
        }
    }
}

#if DEBUG

#Preview {
    CounterpartiesPickerView(
        store: Store(
            state: AddExpenseState(
                currency: .russianRuble,
                amount: 1,
                splitRule: .equally,
                paidByHost: true,
                title: "title",
                host: .previewHost,
                counterparty: .previewCounterparty,
                availableCounterparties: [
                    modify(User.previewCounterparty) { $0.payload.avatar = nil }
                ]
            ),
            reducer: { state, _ in state }
        )
    )
    .environment(ColorPalette.dark)
    .debugBorder()
    .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
