import SwiftUI
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
                        hint: "Display Name"
                    )
                )
                DesignSystem.TextField(
                    text: $displayNameValueEmpty,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Display Name",
                        hint: "Display Name"
                    )
                )
                DesignSystem.TextField(
                    text: $passwordValue,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Password",
                        hint: "Password",
                        content: .password
                    )
                )
                DesignSystem.TextField(
                    text: $passwordValueEmpty,
                    config: DesignSystem.TextField.Config(
                        placeholder: "Enter Password",
                        hint: "Password",
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
    TextFieldsView()
        .preview(packageClass: DebugMenuModel.self)
}
