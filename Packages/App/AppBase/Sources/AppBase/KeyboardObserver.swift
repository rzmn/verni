import UIKit
import Combine
import SwiftUI
internal import Base

@MainActor public struct AppServices: Sendable {
    public static let `default` = AppServices(keyboard: Keyboard(), haptic: DefaultHapticManager())

    public let keyboard: Keyboard
    public let haptic: HapticManager
}

private extension Notification {
    var keyboardFrame: CGRect? {
        guard let object = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] else {
            return nil
        }
        guard let value = object as? NSValue else {
            return nil
        }
        return value.cgRectValue
    }

    var animationDuration: TimeInterval? {
        guard let object = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] else {
            return nil
        }
        guard let number = object as? NSNumber else {
            return nil
        }
        return number.doubleValue
    }

    var animationCurve: UIView.AnimationCurve? {
        guard let object = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] else {
            return nil
        }
        guard let number = object as? NSNumber else {
            return nil
        }
        return UIView.AnimationCurve(rawValue: number.intValue)
    }
}

@MainActor public struct Keyboard {
    public struct Event {
        public enum Kind {
            case willHide
            case willChangeFrame(CGRect)
        }
        public let kind: Kind
        public let animationDuration: TimeInterval
        let curve: UIView.AnimationCurve
        public var options: UIView.AnimationOptions {
            switch curve {
            case .easeIn:
                return .curveEaseIn
            case .easeOut:
                return .curveEaseOut
            case .easeInOut:
                return .curveEaseInOut
            case .linear:
                return .curveLinear
            @unknown default:
                return .curveEaseInOut
            }
        }
    }

    public var eventPublisher: AnyPublisher<Event, Never> {
        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap(mapKeyboardNotification)
        let willChangeFrame = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap(mapKeyboardNotification)
        return Publishers.Merge(willHide, willChangeFrame)
            .eraseToAnyPublisher()
    }

    private func mapKeyboardNotification(_ notification: Notification) -> Event? {
        guard let keyboardFrame = notification.keyboardFrame else {
            return nil
        }
        let duration = notification.animationDuration ?? 0.25
        let curve = notification.animationCurve ?? .easeInOut
        switch notification.name {
        case UIResponder.keyboardWillHideNotification:
            return Event(
                kind: .willHide,
                animationDuration: duration,
                curve: curve
            )
        default:
            return Event(
                kind: .willChangeFrame(keyboardFrame),
                animationDuration: duration,
                curve: curve
            )
        }
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
            UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first { $0 is UIWindowScene }
                .flatMap { $0 as? UIWindowScene }?
                .windows
                .first(where: \.isKeyWindow)?
                .endEditing(true)
        }
    }
}
