import Domain
import Base

struct OrderedSequenceCRDT<Element: Comparable> {
    struct Operation: TimeOrderedOperation {
        enum Kind {
            case insert(Element)
            case delete(Element)
        }
        let kind: Kind
        let id: String
        let timestamp: MsSince1970
        
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

    init(initial: [Element], history: [(elements: [Element], operation: Operation)] = []) {
        self.initial = initial
        self.history = history
    }
}

extension OrderedSequenceCRDT {
    var elements: [Element] {
        history.last?.elements ?? initial
    }
    
    func byInserting(operation: Operation) -> OrderedSequenceCRDT {
        byInserting(operations: [operation])
    }

    func byInserting(operations: [Operation]) -> OrderedSequenceCRDT {
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
