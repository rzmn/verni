import UIKit

public class SegmentedControl: UISegmentedControl {
    public struct Config {
        public struct Item {
            let title: String
            let action: (() -> Void)?

            public init(title: String, action: (() -> Void)? = nil) {
                self.title = title
                self.action = action
            }
        }
        let items: [Item]

        public init(items: [Item]) {
            self.items = items
        }
    }
    let config: Config

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        render(config: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func render(config: Config) {
        config.items.enumerated().forEach { (index, item) in
            insertSegment(withTitle: item.title, at: index, animated: false)
            if let action = item.action {
                setAction(UIAction(handler: { _ in action() }), forSegmentAt: index)
            }
        }
    }
}
