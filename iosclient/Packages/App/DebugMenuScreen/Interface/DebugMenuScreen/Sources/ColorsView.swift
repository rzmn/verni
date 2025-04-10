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

    private var colorItems: [ColorItem] {
        [
            ColorItem(color: \ColorPalette.text.primary.staticLight, name: "text/primary/staticLight"),
            ColorItem(color: \ColorPalette.text.primary.alternative, name: "text/primary/alternative"),
            ColorItem(color: \ColorPalette.text.primary.default, name: "text/primary/default"),
            ColorItem(color: \ColorPalette.text.secondary.default, name: "text/secondary/default"),
            ColorItem(color: \ColorPalette.text.tertiary.default, name: "text/tertiary/default"),
            ColorItem(color: \ColorPalette.text.negative.default, name: "text/negative/default"),
            ColorItem(color: \ColorPalette.background.primary.alternative, name: "background/primary/alternative"),
            ColorItem(color: \ColorPalette.background.brand.static, name: "background/brand/static"),
            ColorItem(color: \ColorPalette.background.primary.default, name: "background/primary/default"),
            ColorItem(color: \ColorPalette.background.secondary.alternative, name: "background/secondary/alternative"),
            ColorItem(color: \ColorPalette.background.secondary.default, name: "background/secondary/default"),
            ColorItem(color: \ColorPalette.background.negative.default, name: "background/negative/default"),
            ColorItem(color: \ColorPalette.background.positive.default, name: "background/positive/default"),
            ColorItem(color: \ColorPalette.icon.primary.staticLight, name: "icon/primary/staticLight"),
            ColorItem(color: \ColorPalette.icon.primary.default, name: "icon/primary/default"),
            ColorItem(color: \ColorPalette.icon.secondary.default, name: "icon/secondary/default"),
            ColorItem(color: \ColorPalette.icon.tertiary.default, name: "icon/tertiary/default"),
            ColorItem(color: \ColorPalette.icon.negative.default, name: "icon/negative/default"),
            ColorItem(color: \ColorPalette.icon.positive.default, name: "icon/positive/default")
        ]
    }

    var body: some View {
        VStack {
            Spacer()
            ForEach(colorItems) { (item: ColorItem) in
                HStack {
                    Text(item.name)
                        .font(.medium(size: 13))
                        .foregroundStyle(colors.text.primary.staticLight)
                    Spacer()
                    Image(systemName: "sun.max")
                        .foregroundStyle(colors.icon.primary.staticLight)
                    Color.gray
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay {
                            item.color(.light)
                                .frame(width: 42, height: 42)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    Image(systemName: "moon")
                        .foregroundStyle(colors.icon.primary.staticLight)
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
        .preview(packageClass: ClassToIdentifyBundle.self)
}
