import UIKit
import Combine
internal import Base

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
            guard let frameInfo = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return nil
            }
            let keyboardFrame = frameInfo.cgRectValue

            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
            let curve = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber).flatMap {
                UIView.AnimationCurve(rawValue: $0.intValue)
            } ?? .easeInOut
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
