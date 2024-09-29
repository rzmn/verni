import SwiftUI

private extension UIColor {
    static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
        UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

extension Color {
    public enum Palette {
        public static var accent: Color {
            Color(uiColor: _accent)
        }
        public static var iconSecondary: Color {
            Color(uiColor: _iconSecondary)
        }
        public static var separator: Color {
            Color(uiColor: _separator)
        }
        public static var primary: Color {
            Color(uiColor: _primary)
        }
        public static var backgroundContent: Color {
            Color(uiColor: _backgroundContent)
        }
        public static var background: Color {
            Color(uiColor: _background)
        }
        public static var destructive: Color {
            Color(uiColor: _destructive)
        }
        public static var positive: Color {
            Color(uiColor: _positive)
        }
        public static var warning: Color {
            Color(uiColor: _warning)
        }
        public static var destructiveBackground: Color {
            Color(uiColor: _destructiveBackground)
        }

        private static var _accent: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(216, 150, 248)
                default:
                    return .rgb(27, 79, 114)
                }
            }
        }

        private static var _iconSecondary: UIColor {
            _accent.withAlphaComponent(0.34)
        }

        private static var _separator: UIColor {
            _iconSecondary
        }

        private static var _primary: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(244, 244, 244)
                default:
                    return .rgb(9, 9, 9)
                }
            }
        }

        private static var _backgroundContent: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(49, 54, 63)
                default:
                    return .rgb(218, 218, 218)
                }
            }
        }

        private static var _background: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(34, 40, 49)
                default:
                    return .rgb(237, 236, 234)
                }
            }
        }

        private static var _destructive: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(190, 49, 68)
                default:
                    return .rgb(144, 30, 45)
                }
            }
        }

        private static var _positive: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(73, 186, 74)
                default:
                    return .rgb(54, 138, 55)
                }
            }
        }

        private static var _warning: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(173, 151, 61)
                default:
                    return .rgb(117, 98, 21)
                }
            }
        }

        private static var _destructiveBackground: UIColor {
            _destructive.withAlphaComponent(0.16)
        }
    }

    public static var palette: Palette.Type {
        Palette.self
    }
}
