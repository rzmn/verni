import SwiftUI
internal import DesignSystem

private struct TextItem: Hashable, Identifiable {
    let contentType: TextContentType
    let name: String

    var id: String { name }
}


struct FontsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    var body: some View {
        VStack {
            Spacer()
            ForEach([
                TextItem(contentType: .button, name: "button"),
                TextItem(contentType: .text, name: "text"),
            ]) { item in
                Text(item.name)
                    .fontStyle(item.contentType)
                    .foregroundStyle(colors.text.primary.alternative)
                    .padding(.palette.defaultHorizontal)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(colors.background.secondary.alternative)
    }
}

#Preview {
    FontsView()
        .preview(packageClass: DebugMenuModel.self)
}
