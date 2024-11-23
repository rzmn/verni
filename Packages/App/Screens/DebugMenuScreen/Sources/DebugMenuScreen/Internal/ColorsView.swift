import SwiftUI
internal import DesignSystem

private struct ColorItem: Identifiable, Hashable {
    let color: (ColorPalette) -> Color
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        name
    }
}

struct ColorsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    var body: some View {
        VStack {
            Spacer()
            ForEach([
                ColorItem(color: \ColorPalette.text.primary.alternative, name: "text/primary/alternative"),
                ColorItem(color: \ColorPalette.text.primary.default, name: "text/primary/default"),
                ColorItem(color: \ColorPalette.text.secondary.default, name: "text/secondary/default"),
                ColorItem(color: \ColorPalette.text.tertiary.default, name: "text/tertiary/default"),
                ColorItem(color: \ColorPalette.background.primary.alternative, name: "background/primary/alternative"),
                ColorItem(color: \ColorPalette.background.primary.brand, name: "background/primary/brand"),
                ColorItem(color: \ColorPalette.background.primary.default, name: "background/primary/default"),
                ColorItem(color: \ColorPalette.background.secondary.alternative, name: "background/secondary/alternative"),
                ColorItem(color: \ColorPalette.background.secondary.default, name: "background/secondary/default"),
                ColorItem(color: \ColorPalette.icon.primary.alternative, name: "icon/primary/alternative"),
                ColorItem(color: \ColorPalette.icon.primary.default, name: "icon/primary/default"),
                ColorItem(color: \ColorPalette.icon.secondary.default, name: "icon/secondary/default"),
                ColorItem(color: \ColorPalette.icon.tertiary.default, name: "icon/tertiary/default"),
            ]) { item in
                HStack {
                    Text(item.name)
                        .font(.medium(size: 13))
                        .foregroundStyle(colors.text.primary.alternative)
                    Spacer()
                    Image(systemName: "sun.max")
                        .foregroundStyle(colors.icon.primary.alternative)
                    Color.gray
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay {
                            item.color(.light)
                                .frame(width: 42, height: 42)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    Image(systemName: "moon")
                        .foregroundStyle(colors.icon.primary.alternative)
                    Color.gray
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay {
                            item.color(.dark)
                                .frame(width: 42, height: 42)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                }
                .padding(.horizontal, .palette.defaultHorizontal)
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
    }
}

#Preview {
    ColorsView()
        .preview(packageClass: DebugMenuModel.self)
}
