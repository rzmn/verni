import SwiftUI
import AppBase
internal import DesignSystem

struct TextFieldsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    @State var displayNameValue = "display name value"
    @State var displayNameValueEmpty = ""
    @State var passwordValue = "password"
    @State var passwordValueEmpty = ""

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                DesignSystem.TextField(
                    text: $displayNameValue,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Display Name",
                        hint: .hintsEnabled(LocalizedStringKey("Display Name")),
                        content: .displayName
                    )
                )
                DesignSystem.TextField(
                    text: $displayNameValueEmpty,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Display Name",
                        hint: .hintsEnabled(LocalizedStringKey("Display Name")),
                        content: .displayName
                    )
                )
                DesignSystem.TextField(
                    text: $displayNameValue,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Email",
                        content: .email
                    )
                )
                DesignSystem.TextField(
                    text: $displayNameValueEmpty,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Email",
                        content: .email
                    )
                )
                DesignSystem.TextField(
                    text: $passwordValue,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Password",
                        hint: .hintsEnabled(LocalizedStringKey("Password")),
                        content: .password
                    )
                )
                DesignSystem.TextField(
                    text: $passwordValueEmpty,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Password",
                        hint: .hintsEnabled(LocalizedStringKey("Password")),
                        content: .password
                    )
                )
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
        .keyboardDismiss()
    }
}

#Preview {
    DebugMenuView(
        store: Store(
            state: DebugMenuState(
                navigation: [],
                sections: [
                    .designSystem(
                        DesignSystemState(
                            sections: [
                                .button,
                                .colors,
                                .fonts
                            ],
                            section: nil
                        )
                    )
                ],
                section: nil
            ),
            reducer: { state, _ in state }
        )
    )
    .preview(packageClass: ClassToIdentifyBundle.self)
}
