import SwiftUI

extension Color {
    public enum Palette {
        public static var accent: Color {
            Color(uiColor: UIColorsPalette.accent)
        }
        public static var buttonText: Color {
            Color(uiColor: UIColorsPalette.buttonText)
        }
        public static var primary: Color {
            Color(uiColor: UIColorsPalette.primary)
        }
        public static var backgroundContent: Color {
            Color(uiColor: UIColorsPalette.backgroundContent)
        }
        public static var background: Color {
            Color(uiColor: UIColorsPalette.background)
        }
        public static var destructive: Color {
            Color(uiColor: UIColorsPalette.destructive)
        }
        public static var dimBackground: Color {
            Color(uiColor: UIColorsPalette.dimBackground)
        }
        public static var positive: Color {
            Color(uiColor: UIColorsPalette.positive)
        }
        public static var warning: Color {
            Color(uiColor: UIColorsPalette.warning)
        }
    }

    public static var palette: Palette.Type {
        Palette.self
    }
}

private extension UIColor {
    static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
        UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }

    static func gray(_ value: Int) -> UIColor {
        .rgb(value, value, value)
    }
}

private extension UIColor {
    var dark: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }

    var light: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
}

private struct UIColorsPalette {
    static var accent: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(228, 146, 115)
            default:
                return .rgb(78, 65, 135)
            }
        }
    }

    static var buttonText: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .white
            default:
                return .white
            }
        }
    }

    static var primary: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(244, 244, 244)
            default:
                return .rgb(9, 9, 9)
            }
        }
    }

    static var backgroundContent: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(49, 54, 63)
            default:
                return .rgb(227, 226, 224)
            }
        }
    }

    static var background: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(34, 40, 49)
            default:
                return .rgb(237, 236, 234)
            }
        }
    }

    static var dimBackground: UIColor {
        .black.withAlphaComponent(0.18)
    }

    static var destructive: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(190, 49, 68)
            default:
                return .rgb(191, 67, 66)
            }
        }
    }

    static var positive: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(73, 186, 74)
            default:
                return .rgb(54, 138, 55)
            }
        }
    }

    static var warning: UIColor {
        UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .rgb(173, 151, 61)
            default:
                return .rgb(117, 98, 21)
            }
        }
    }
}

private struct ColorItem: Identifiable, Hashable {
    let uiColor: UIColor
    let name: String

    var id: String {
        name
    }
}

#Preview {
    VStack {
        ForEach([
            ColorItem(uiColor: UIColorsPalette.accent, name: "accent"),
            ColorItem(uiColor: UIColorsPalette.primary, name: "primary"),
            ColorItem(uiColor: UIColorsPalette.backgroundContent, name: "background content"),
            ColorItem(uiColor: UIColorsPalette.background, name: "background"),
            ColorItem(uiColor: UIColorsPalette.destructive, name: "destructive"),
            ColorItem(uiColor: UIColorsPalette.positive, name: "positive"),
            ColorItem(uiColor: UIColorsPalette.warning, name: "warning")
        ]) { color in
            HStack {
                Text(color.name)
                Spacer()
                Image(systemName: "sun.max")
                Color(uiColor: color.uiColor.light)
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 8))
                Image(systemName: "moon")
                Color(uiColor: color.uiColor.dark)
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 8))
            }
            .padding(.horizontal, .palette.defaultHorizontal)
        }
    }
}
