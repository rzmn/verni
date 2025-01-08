import PersistentStorage

struct OperationsMergeResult<Element: IdentifiableOperation> {
    let inserted: [Element]
    let all: [Element]
}

extension Sequence where Element: IdentifiableOperation {
    var sorted: [Element] {
        sorted { lhs, rhs in
            guard lhs.timestamp != rhs.timestamp else {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }
    
    func merged<Other: Sequence>(with other: Other) -> OperationsMergeResult<Element> where Other.Element == Element {
        var idToOperation = [String: Element]()
        for element in self {
            idToOperation[element.id] = element
        }
        var inserted = [Element]()
        for element in other where idToOperation[element.id] == nil {
            idToOperation[element.id] = element
            inserted.append(element)
            
        }
        return OperationsMergeResult(
            inserted: inserted.sorted,
            all: idToOperation.values.sorted
        )
    }
}
