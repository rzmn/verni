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
    
    public var icon: Icon {
        Icon(theme: theme)
    }
}
