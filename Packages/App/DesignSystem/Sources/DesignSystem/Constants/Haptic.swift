import UIKit

public protocol HapticHandler {
    func perform()
}

struct BlockHapticHandler: HapticHandler {
    private let performBlock: () -> Void
    
    init(performBlock: @escaping () -> Void) {
        self.performBlock = performBlock
    }
    
    func perform() {
        performBlock()
    }
}

@MainActor public enum HapticEngine {
    public static var error: HapticHandler {
        BlockHapticHandler {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    public static var warning: HapticHandler {
        BlockHapticHandler {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
    
    public static var success: HapticHandler {
        BlockHapticHandler {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    public static var lightImpact: HapticHandler {
        BlockHapticHandler {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    public static var mediumImpact: HapticHandler {
        BlockHapticHandler {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    public static var heavyImpact: HapticHandler {
        BlockHapticHandler {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    public static var selectionChanged: HapticHandler {
        BlockHapticHandler {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
