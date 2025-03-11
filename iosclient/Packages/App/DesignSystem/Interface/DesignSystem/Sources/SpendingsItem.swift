import SwiftUI

public struct SpendingsItem: View {
    @Environment(ColorPalette.self) var colors

    public enum Style {
        case positive
        case negative
    }

    public struct Config {
        let avatar: AvatarView.AvatarId?
        let name: String
        let style: Style
        let amount: String

        public init(avatar: AvatarView.AvatarId?, name: String, style: Style, amount: String) {
            self.avatar = avatar
            self.name = name
            self.style = style
            self.amount = amount
        }
    }
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        HStack(spacing: 0) {
            userPreview
                .padding(.leading, 12)
            Spacer()
            spendingAmountPreview
                .padding(.trailing, 12)

        }
        .frame(height: 94)
        .background(colors.background.primary.default)
        .clipShape(.rect(cornerRadius: 24))
    }

    private var accessoryText: LocalizedStringKey {
        switch config.style {
        case .positive:
            .spendingsPositiveBalance
        case .negative:
            .spendingsNegativeBalance
        }
    }

    private var userPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            AvatarView(avatar: config.avatar)
                .frame(width: 38, height: 38)
                .clipShape(.rect(cornerRadius: 19))
                .padding(.top, 12)
            Spacer()
            Text(config.name)
                .font(.medium(size: 20))
                .foregroundStyle(colors.text.primary.default)
                .padding(.bottom, 12)
        }
    }

    private var spendingAmountPreview: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
            Text(accessoryText)
                .foregroundStyle(colors.text.secondary.default)
                .font(.medium(size: 15))
            HStack {
                accesoryIcon
                    .frame(width: 20, height: 20)
                    .foregroundStyle(accesoryIconForeground)
                    .background(accesoryIconBackground)
                    .clipShape(.rect(cornerRadius: 4))
                Text(config.amount)
                    .font(.medium(size: 20))
                    .foregroundStyle(colors.text.primary.default)
            }
            .padding(.top, 2)
            .padding(.bottom, 12)
        }
    }

    private var accesoryIcon: Image {
        switch config.style {
        case .positive:
            .plus
        case .negative:
            .minus
        }
    }

    private var accesoryIconBackground: Color {
        switch config.style {
        case .positive:
            colors.background.positive.default
        case .negative:
            colors.background.negative.default
        }
    }

    private var accesoryIconForeground: Color {
        switch config.style {
        case .positive:
            colors.icon.positive.default
        case .negative:
            colors.icon.negative.default
        }
    }
}

#Preview {
    VStack {
        Spacer()
        SpendingsItem(
            config: SpendingsItem.Config(
                avatar: "123",
                name: "berchikk",
                style: .negative,
                amount: "23$"
            )
        )
        Spacer()
    }
    .background(.gray)
    .environment(AvatarView.Repository(getBlock: { _ in
        Data.stubAvatar
    }))
    .environment(ColorPalette.dark)
    .loadCustomFonts()
}
