import UIKit
import Combine
internal import Base

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

@MainActor public class KeyboardObserver {
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

    public let notifier: PassthroughSubject<Event, Never>
    private var subscriptions = Set<AnyCancellable>()

    private init() {
        notifier = PassthroughSubject<Event, Never>()
        let mapper = { (notification: Notification) -> Event? in
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
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap(mapper)
            .sink(receiveValue: notifier.send)
            .store(in: &subscriptions)
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap(mapper)
            .sink(receiveValue: notifier.send)
            .store(in: &subscriptions)
    }
}
