import Foundation

extension CGFloat {
    public enum Paddings {
        public static var defaultHorizontal: CGFloat {
            16
        }

        public static var defaultVertical: CGFloat {
            16
        }

        public static var vButtonSpacing: CGFloat {
            18
        }

        public static var buttonHeight: CGFloat {
            50
        }

        public static var iconSize: CGFloat {
            48
        }
    }

    public static var palette: Paddings.Type {
        Paddings.self
    }
}
