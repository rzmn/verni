import UIKit

public protocol HapticManager: Sendable {
    @MainActor func errorHaptic()
    @MainActor func successHaptic()
    @MainActor func warningHaptic()
    @MainActor func submitHaptic()
}

public extension HapticManager {
    @MainActor func errorHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    @MainActor func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor func submitHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.66)
    }

    @MainActor func warningHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

public struct DefaultHapticManager: HapticManager {
    public init() {}
}
