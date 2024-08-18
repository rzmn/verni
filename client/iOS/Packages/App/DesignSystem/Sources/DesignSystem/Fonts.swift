import UIKit

extension UIFont {
    public enum Predefined {
        public static var title1: UIFont {
            UIFont(name: "SF Pro Display Semibold", size: 36) ?? .systemFont(ofSize: 28, weight: .bold)
        }

        public static var title2: UIFont {
            return UIFont(name: "SF Pro", size: 17) ?? .systemFont(ofSize: 18, weight: .bold)
        }

        public static var title3: UIFont {
            UIFont(name: "SF Pro Display Semibold", size: 15) ?? .systemFont(ofSize: 18, weight: .bold)
        }

        public static var subtitle: UIFont {
            UIFont(name: "SF Pro Display Semibold", size: 12) ?? .systemFont(ofSize: 13, weight: .bold)
        }

        public static var text: UIFont {
            UIFont(name: "SF Pro", size: 16) ?? .systemFont(ofSize: 16)
        }

        public static var secondaryText: UIFont {
            UIFont(name: "SF Pro", size: 13) ?? .systemFont(ofSize: 13)
        }

        public static var placeholder: UIFont {
            UIFont(name: "SF Pro", size: 13) ?? .systemFont(ofSize: 13)
        }
    }
    public static var p: Predefined.Type {
        Predefined.self
    }
}
