import Foundation

public protocol EventSource<Event>: Sendable {
    associatedtype Event: Sendable
    
    func subscribeWeak<O: AnyObject & Sendable>(
        _ weakObject: O,
        block: @escaping @Sendable (Event) -> Void
    ) async
}

public actor EventPublisher<Event: Sendable> {
    private var weakSubscriptions = [Subscription]()
    
    public init() {}
    
    public func notify(_ event: Event) {
        weakSubscriptions = weakSubscriptions.reduce(
            into: [], { array, subscription in
                guard subscription.isAlive() else {
                    return
                }
                subscription.block(event)
                array.append(subscription)
            }
        )
    }
}

extension EventPublisher where Event == Void {
    public func notify() {
        notify(())
    }
}

extension EventPublisher: EventSource {
    public func subscribeWeak<O: AnyObject & Sendable>(_ weakObject: O, block: @escaping @Sendable (Event) -> Void) {
        weakSubscriptions.append(
            Subscription(weakObject: weakObject, block: block)
        )
    }
}

extension EventPublisher {
    private struct Subscription: Hashable {
        let isAlive: () -> Bool
        let block: @Sendable (Event) -> Void
        private let id = NSObject()
        
        init<O: AnyObject>(weakObject: O, block: @escaping @Sendable (Event) -> Void) {
            self.isAlive = { [weak weakObject] in
                weakObject != nil
            }
            self.block = block
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Subscription, rhs: Subscription) -> Bool {
            lhs.id === rhs.id
        }
    }
}
