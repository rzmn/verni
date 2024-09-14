import UIKit

public enum Alert {
    public struct Action {
        public let title: String
        public let handler: ((UIViewController) async -> Void)?

        public init(title: String, handler: ((UIViewController) async -> Void)? = nil) {
            self.title = title
            self.handler = handler
        }
    }
    public struct Config {
        public let title: String
        public let message: String
        public let actions: [Action]

        public init(title: String, message: String, actions: [Action]) {
            self.title = title
            self.message = message
            self.actions = actions
        }
    }
}
