import UIKit
import Combine
import SwiftUI

extension DS {
    public protocol SegmentedControlItem: Identifiable, Hashable {
        var title: String { get }
        var onSelect: () -> Void { get }
    }

    public struct SegmentedControl<Item: SegmentedControlItem>: View {
        let items: [Item]
        let selected: Binding<Item>

        public var body: some View {
            Picker(
                selection: selected
            ) {
                ForEach(items) { item in
                    Text(item.title)
                }
            } label: {

            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }
}

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
    public var selectedIndexPublisher: AnyPublisher<Int, Never> {
        selectedIndexSubject.eraseToAnyPublisher()
    }
    private let selectedIndexSubject = PassthroughSubject<Int, Never>()
    let config: Config

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        addAction({ [unowned self] in
            selectedIndexSubject.send(selectedSegmentIndex)
        }, for: .valueChanged)
        render(config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
