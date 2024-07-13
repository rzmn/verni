import UIKit

extension UIFont {
    public enum Predefined {
        public static var title1: UIFont {
            UIFont(name: "Menlo-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        }

        public static var title2: UIFont {
            UIFont(name: "Menlo-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        }

        public static var title3: UIFont {
            UIFont(name: "Menlo-Bold", size: 15) ?? .systemFont(ofSize: 18, weight: .bold)
        }

        public static var text: UIFont {
            UIFont(name: "Menlo", size: 16) ?? .systemFont(ofSize: 16)
        }

        public static var secondaryText: UIFont {
            UIFont(name: "Menlo", size: 13) ?? .systemFont(ofSize: 13)
        }

        public static var placeholder: UIFont {
            UIFont(name: "Menlo", size: 13) ?? .systemFont(ofSize: 13)
        }
    }
    public static var p: Predefined.Type {
        Predefined.self
    }
}
