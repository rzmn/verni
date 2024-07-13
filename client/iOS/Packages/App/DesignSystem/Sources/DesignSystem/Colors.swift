import UIKit

private extension UIColor {
    static func rgb(_ r: Int, _ g: Int, _ b: Int) -> UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

extension UIColor {
    public enum Palette {
        public static var accent: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(216, 150, 248)
                default:
                    return .rgb(27, 79, 114)
                }
            }
        }

        public static var iconSecondary: UIColor {
            accent.withAlphaComponent(0.34)
        }

        public static var separator: UIColor {
            iconSecondary
        }

        public static var primary: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(244, 244, 244)
                default:
                    return .rgb(9, 9, 9)
                }
            }
        }

        public static var backgroundContent: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(49, 54, 63)
                default:
                    return .rgb(218, 218, 218)
                }
            }
        }

        public static var background: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(34, 40, 49)
                default:
                    return .rgb(237, 236, 234)
                }
            }
        }

        public static var destructive: UIColor {
            UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return .rgb(190, 49, 68)
                default:
                    return .rgb(144, 30, 45)
                }
            }
        }
    }

    public static var p: Palette.Type {
        Palette.self
    }
}
