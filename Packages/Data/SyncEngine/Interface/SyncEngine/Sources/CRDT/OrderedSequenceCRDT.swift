internal import Convenience

public struct OrderedSequenceCRDT<Element: Comparable & Sendable>: Sendable {
    public struct Operation: TimeOrderedOperation {
        public enum Kind: Sendable {
            case insert(Element)
            case delete(Element)
        }
        public let kind: Kind
        public let id: String
        public let timestamp: Int64
        
        public init(kind: Kind, id: String, timestamp: Int64) {
            self.kind = kind
            self.id = id
            self.timestamp = timestamp
        }
        
        func apply(elements: inout [Element]) {
            switch kind {
            case .insert(let element):
                elements.append(element)
                elements.sort()
            case .delete(let element):
                elements.removeAll {
                    $0 == element
                }
            }
        }
    }
    
    private let initial: [Element]
    private let history: [(elements: [Element], operation: Operation)]

    public init(
        initial: [Element],
        history: [(elements: [Element], operation: Operation)] = []
    ) {
        self.initial = initial
        self.history = history
    }
}

extension OrderedSequenceCRDT {
    public var elements: [Element] {
        history.last?.elements ?? initial
    }
    
    public func byInserting(operation: Operation) -> OrderedSequenceCRDT {
        byInserting(operations: [operation])
    }

    public func byInserting(operations: [Operation]) -> OrderedSequenceCRDT {
        let operations = (history.map(\.operation) + operations)
            .reduce(
                into: [:]
            ) { dict, operation in
                dict[operation.id] = operation
            }
            .values
            .ordered()
        var current = initial
        return OrderedSequenceCRDT(
            initial: initial,
            history: operations.map { operation in
                operation.apply(elements: &current)
                return (elements: current, operation: operation)
            }
        )
    }
}
