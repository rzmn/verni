import SwiftUI

@Observable @MainActor public class ColorPalette: Sendable {
    enum Theme {
        case dark
        case light
    }
    
    private(set) var theme: Theme
    
    convenience init() {
        self.init(
            theme: {
                switch UIScreen.main.traitCollection.userInterfaceStyle {
                case .dark:
                    .dark
                default:
                    .light
                }
            }()
        )
    }
    
    private init(theme: Theme) {
        self.theme = theme
    }
    
    public static var dark: ColorPalette {
        ColorPalette(theme: .dark)
    }
    
    public static var light: ColorPalette {
        ColorPalette(theme: .light)
    }
}

private extension Color {
    static func hex(_ code: UInt) -> Color {
        let component: (UInt) -> Double = { shift in
            Double((code >> shift) & 0xff) / 255
        }
        return Color(.sRGB, red: component(16), green: component(8), blue: component(0))
    }
}

extension ColorPalette {
    public struct Text {
        let theme: Theme
        
        public struct Primary {
            let theme: Theme
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0xFFFFFF)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x051125)
                case .light:
                    .hex(0x051125)
                }
            }
        }
        
        public struct Secondary {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x69707C)
                case .light:
                    .hex(0x69707C)
                }
            }
        }
        
        public struct Tertiary {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x9BA0A8)
                case .light:
                    .hex(0x9BA0A8)
                }
            }
        }
        
        public var primary: Primary {
            Primary(theme: theme)
        }
        
        public var secondary: Secondary {
            Secondary(theme: theme)
        }
        
        public var tertiary: Tertiary {
            Tertiary(theme: theme)
        }
    }
    
    public var text: Text {
        Text(theme: theme)
    }
}

extension ColorPalette {
    public struct Background {
        let theme: Theme
        
        public struct Primary {
            let theme: Theme
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0xFFFFFF)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
            
            public var brand: Color {
                switch theme {
                case .dark:
                    .hex(0x593EFF)
                case .light:
                    .hex(0x593EFF)
                }
            }
        }
        
        public struct Secondary {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xEBECEE)
                case .light:
                    .hex(0xEBECEE)
                }
            }
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0x374151)
                case .light:
                    .hex(0x374151)
                }
            }
        }
        
        public var primary: Primary {
            Primary(theme: theme)
        }
        
        public var secondary: Secondary {
            Secondary(theme: theme)
        }
    }
    
    public var background: Background {
        Background(theme: theme)
    }
}

extension ColorPalette {
    public struct Icon {
        let theme: Theme
        
        public struct Primary {
            let theme: Theme
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0xFFFFFF)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x051125)
                case .light:
                    .hex(0x051125)
                }
            }
        }
        
        public struct Tertiary {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x9BA0A8)
                case .light:
                    .hex(0x9BA0A8)
                }
            }
        }
        
        public var primary: Primary {
            Primary(theme: theme)
        }
        
        public var tertiary: Tertiary {
            Tertiary(theme: theme)
        }
    }
    
    public var icon: Icon {
        Icon(theme: theme)
    }
}

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

#Preview {
    VStack {
        ForEach([
            ColorItem(color: \ColorPalette.text.primary.alternative, name: "text/primary/alternative"),
            ColorItem(color: \ColorPalette.text.primary.default, name: "text/primary/default"),
            ColorItem(color: \ColorPalette.text.secondary.default, name: "text/secondary/default"),
            ColorItem(color: \ColorPalette.text.tertiary.default, name: "text/tertiary/default"),
            ColorItem(color: \ColorPalette.background.primary.alternative, name: "background/primary/alternative"),
            ColorItem(color: \ColorPalette.background.primary.brand, name: "background/primary/brand"),
            ColorItem(color: \ColorPalette.background.secondary.alternative, name: "background/secondary/alternative"),
            ColorItem(color: \ColorPalette.background.secondary.default, name: "background/secondary/default"),
            ColorItem(color: \ColorPalette.icon.primary.alternative, name: "icon/primary/alternative"),
            ColorItem(color: \ColorPalette.icon.primary.default, name: "icon/primary/default"),
            ColorItem(color: \ColorPalette.icon.tertiary.default, name: "icon/tertiary/default"),
        ]) { item in
            HStack {
                Text(item.name)
                Spacer()
                Image(systemName: "sun.max")
                Color.gray
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay {
                        item.color(.light)
                            .frame(width: 42, height: 42)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                Image(systemName: "moon")
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
    }
}
