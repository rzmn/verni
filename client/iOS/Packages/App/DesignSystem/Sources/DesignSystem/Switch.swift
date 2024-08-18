import UIKit

public class Switch: UISwitch {
    public struct Config {
        public let on: Bool

        public init(on: Bool) {
            self.on = on
        }
    }
    let config: Config

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    public func render(config: Config) {

    }
}
