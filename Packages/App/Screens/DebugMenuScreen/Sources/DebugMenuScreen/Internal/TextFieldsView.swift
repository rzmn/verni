import SwiftUI
internal import DesignSystem

struct TextFieldsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                DesignSystem.TextField(
                    text: .constant(""),
                    config: DesignSystem.TextField.Config(placeholder: "Label", hint: "Hint")
                )
                DesignSystem.TextField(
                    text: .constant("Text"),
                    config: DesignSystem.TextField.Config(placeholder: "Label", hint: "Hint")
                )
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
    }
}

#Preview {
    TextFieldsView()
        .environment(ColorPalette.dark)
        .environment(PaddingsPalette.default)
        .loadCustomFonts()
        .ignoresSafeArea()
        .background(Color.white)
}
