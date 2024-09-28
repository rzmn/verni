import SwiftUI

extension Image {
    public enum Palette {
        public static var cross: Image {
            Image(systemName: "xmark")
        }
    }

    public static var palette: Palette.Type {
        Palette.self
    }
}
