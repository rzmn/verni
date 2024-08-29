import UIKit
import Combine

public class Switch: UISwitch {
    public struct Config {
        public let on: Bool

        public init(on: Bool) {
            self.on = on
        }
    }
    public var isOnPublisher: AnyPublisher<Bool, Never> {
        isOnSubject.eraseToAnyPublisher()
    }
    let config: Config
    let isOnSubject = PassthroughSubject<Bool, Never>()

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        addAction({ [unowned self] in
            isOnSubject.send(isOn)
        }, for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    public func render(config: Config) {

    }
}
