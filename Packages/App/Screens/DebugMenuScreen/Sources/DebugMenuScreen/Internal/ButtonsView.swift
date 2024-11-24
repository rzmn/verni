import SwiftUI
internal import DesignSystem

private struct ConfigForPreview: Identifiable {
    let config: DesignSystem.Button.Config
    
    var id: String {
        "\(config)"
    }
}

struct ButtonsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                let image = Image(systemName: "heart.fill")
                let configs = [.primary, .secondary, .tertiary].flatMap { (style: DesignSystem.Button.Style) -> [DesignSystem.Button.Config] in
                    [.left(image), .right(image), nil].map { icon in
                        DesignSystem.Button.Config(style: style, text: "LABEL", icon: icon)
                    }
                }.map(ConfigForPreview.init)
                
                ForEach(configs) { identifiableWrapper in
                    Button(config: identifiableWrapper.config, action: {})
                }
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
    }
}

#Preview {
    ButtonsView()
        .preview(packageClass: DebugMenuModel.self)
}
