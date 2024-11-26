import SwiftUI
import AppBase
import Domain
internal import DesignSystem

public struct ProfileView: View {
    @ObservedObject var store: Store<SpendingsState, SpendingsAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<SpendingsState, SpendingsAction>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                IconButton(
                    config: IconButton.Config(
                        style: .primary,
                        icon: .search
                    )
                ) {
                    store.dispatch(.onSearchTap)
                }
            }
            .frame(height: 54)
            .overlay {
                Text(.spendingsTitle)
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.primary.default)
            }
            overallSection
            ForEach(items) { (item: SpendingsState.Item) in
                SpendingsItem(
                    config: SpendingsItem.Config(
                        avatar: item.user.avatar,
                        name: item.user.displayName,
                        style: .negative,
                        amount: ""
                    )
                )
            }
            Spacer()
        }
        .background(colors.background.secondary.default)
    }
    
    private var items: [SpendingsState.Item] {
        store.state.previews.value ?? []
    }

    private var overallSection: some View {
        HStack(spacing: 0) {
            Image.chevronDown
                .frame(width: 24, height: 24)
                .padding(.leading, 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(.spendingsOverallTitle)
                    .font(.bold(size: 15))
                    .foregroundStyle(colors.text.primary.alternative)
                    .padding(.top, 20)
                Spacer()
                Text(.spendingsPeopleInvolved(count: store.state.previews.value?.count ?? 0))
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.secondary.alternative)
                    .padding(.bottom, 20)
            }
            .padding(.leading, 12)
            Spacer()
        }
        .background(colors.background.primary.alternative)
        .frame(height: 82)
        .clipShape(.rect(cornerRadius: 24))
    }
}

#Preview {
    ProfileView(
        store: Store(
            state: SpendingsState(
                previews: .loaded(
                    [
                        SpendingsState.Item(
                            user: User(
                                id: UUID().uuidString,
                                status: .friend,
                                displayName: "berchikk",
                                avatar: nil
                            ),
                            balance: [
                                .euro: 123
                            ]
                        )
                    ]
                )
            ),
            reducer: SpendingsModel.reducer
        )
    )
    .environment(ColorPalette.dark)
    .environment(AvatarView.Repository.preview)
    .preview(packageClass: SpendingsModel.self)
}
