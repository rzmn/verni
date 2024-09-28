import SwiftUI

extension Font {
    public enum Predefined {
        public static var title1: Font {
            Font(UIFont(name: "SF Pro Display Semibold", size: 36) ?? .systemFont(ofSize: 28, weight: .bold))
        }

        public static var title2: Font {
            Font(UIFont(name: "SF Pro", size: 17) ?? .systemFont(ofSize: 18, weight: .bold))
        }

        public static var title3: Font {
            Font(UIFont(name: "SF Pro Display Semibold", size: 15) ?? .systemFont(ofSize: 18, weight: .bold))
        }

        public static var subtitle: Font {
            Font(UIFont(name: "SF Pro Display Semibold", size: 12) ?? .systemFont(ofSize: 13, weight: .bold))
        }

        public static var text: Font {
            Font(UIFont(name: "SF Pro", size: 16) ?? .systemFont(ofSize: 16))
        }

        public static var secondaryText: Font {
            Font(UIFont(name: "SF Pro", size: 13) ?? .systemFont(ofSize: 13))
        }

        public static var placeholder: Font {
            Font(UIFont(name: "SF Pro", size: 13) ?? .systemFont(ofSize: 13))
        }
    }
    public static var palette: Predefined.Type {
        Predefined.self
    }
}
