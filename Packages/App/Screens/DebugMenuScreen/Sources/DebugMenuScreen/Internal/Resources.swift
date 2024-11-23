import SwiftUI

extension Image {
    static var logoHorizontal: Image {
        Image("logo-horizontal", bundle: .module)
    }
}

extension LocalizedStringKey {
    static var buttonsSection: LocalizedStringKey {
        key("buttons_section")
    }
    
    static var colorsSection: LocalizedStringKey {
        key("colors_section")
    }
    
    static var fontsSection: LocalizedStringKey {
        key("fonts_section")
    }
    
    static var textFieldsSection: LocalizedStringKey {
        key("text_fields_section")
    }
    
    static var designSystemSection: LocalizedStringKey {
        key("design_system_section")
    }
    
    static var debugMenuTitle: LocalizedStringKey {
        key("debug_menu_title")
    }
    
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
}
