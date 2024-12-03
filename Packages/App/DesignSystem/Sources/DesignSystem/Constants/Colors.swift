import SwiftUI

@Observable @MainActor public class ColorPalette: Sendable {
    enum Theme {
        case dark
        case light
    }
    
    private(set) var theme: Theme
    
    public convenience init(scheme: ColorScheme) {
        self.init(
            theme: {
                switch scheme {
                case .light:
                    .light
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
            
            public var staticLight: Color {
                switch theme {
                case .dark:
                    .hex(0xFFFFFF)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0x051125)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xFFFFFF)
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
                    .hex(0x9BA0A8)
                case .light:
                    .hex(0x69707C)
                }
            }
            
            public var alternative: Color {
                switch theme {
                case .dark:
                    .hex(0x69707C)
                case .light:
                    .hex(0x9BA0A8)
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
        
        public struct Negative {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xCB2C30)
                case .light:
                    .hex(0xCB2C30)
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
        
        public var negative: Negative {
            Negative(theme: theme)
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
                    .hex(0x051125)
                }
            }
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x051125)
                case .light:
                    .hex(0xFFFFFF)
                }
            }
        }
        
        public struct Brand {
            let theme: Theme
            
            public var `static`: Color {
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
                    .hex(0x374151)
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
        
        public struct Negative {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xFFEBEB)
                case .light:
                    .hex(0xFFEBEB)
                }
            }
        }
        
        public struct Positive {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xE7F6EC)
                case .light:
                    .hex(0xE7F6EC)
                }
            }
        }
        
        public var primary: Primary {
            Primary(theme: theme)
        }
        
        public var secondary: Secondary {
            Secondary(theme: theme)
        }
        
        public var brand: Brand {
            Brand(theme: theme)
        }
        
        public var negative: Negative {
            Negative(theme: theme)
        }
        
        public var positive: Positive {
            Positive(theme: theme)
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
            
            public var staticLight: Color {
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
                    .hex(0xFFFFFF)
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
                    .hex(0x9BA0A8)
                case .light:
                    .hex(0x69707C)
                }
            }
        }
        
        public struct Negative {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0xCB2C30)
                case .light:
                    .hex(0xCB2C30)
                }
            }
        }
        
        public struct Positive {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x0E873C)
                case .light:
                    .hex(0x0E873C)
                }
            }
        }
        
        public struct Tertiary {
            let theme: Theme
            
            public var `default`: Color {
                switch theme {
                case .dark:
                    .hex(0x0E873C)
                case .light:
                    .hex(0x0E873C)
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
        
        public var negative: Negative {
            Negative(theme: theme)
        }
        
        public var positive: Positive {
            Positive(theme: theme)
        }
    }
    
    public var icon: Icon {
        Icon(theme: theme)
    }
}
