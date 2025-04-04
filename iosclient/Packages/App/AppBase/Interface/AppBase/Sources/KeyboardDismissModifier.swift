import SwiftUI

extension UIApplication {
    public static func dismissKeyboard() {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first { $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?
            .windows
            .first(where: \.isKeyWindow)?
            .endEditing(true)
    }
}

extension View {
    public func keyboardDismiss() -> some View {
        modifier(KeyboardDismiss())
    }
}

private struct KeyboardDismiss: ViewModifier {
    func body(content: Content) -> some View {
        content.onTapGesture {
            UIApplication.dismissKeyboard()
        }
    }
}
