import UIKit
import Combine
internal import Base

public class KeyboardObserver {
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

    public static let shared = KeyboardObserver()

    public let notifier = PassthroughSubject<Event, Never>()

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main,
            using: weak(self, type(of: self).handle)
        )
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main,
            using: weak(self, type(of: self).handle)
        )
    }

    private func handle(notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber).flatMap {
            UIView.AnimationCurve(rawValue: $0.intValue)
        } ?? .easeInOut

        let event: Event
        if notification.name == UIResponder.keyboardWillHideNotification {
            event = Event(
                kind: .willHide,
                animationDuration: duration,
                curve: curve
            )
        } else {
            event = Event(
                kind: .willChangeFrame(keyboardFrame),
                animationDuration: duration,
                curve: curve
            )
        }
        notifier.send(event)
    }
}
