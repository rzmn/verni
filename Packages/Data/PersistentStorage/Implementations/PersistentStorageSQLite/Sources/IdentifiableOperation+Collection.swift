import PersistentStorage

struct OperationsMergeResult<Element: BaseOperationConvertible> {
    let inserted: [Element]
    let all: [Element]
}

extension Sequence where Element: BaseOperationConvertible {
    var sorted: [Element] {
        sorted { lhs, rhs in
            guard lhs.base.createdAt != rhs.base.createdAt else {
                return lhs.base.operationId < rhs.base.operationId
            }
            return lhs.base.createdAt < rhs.base.createdAt
        }
    }
    
    func merged<Other: Sequence>(with other: Other) -> OperationsMergeResult<Element> where Other.Element == Element {
        var idToOperation = [String: Element]()
        for element in self {
            idToOperation[element.base.operationId] = element
        }
        var inserted = [Element]()
        for element in other where idToOperation[element.base.operationId] == nil {
            idToOperation[element.base.operationId] = element
            inserted.append(element)
            
        }
        return OperationsMergeResult(
            inserted: inserted.sorted,
            all: idToOperation.values.sorted
        )
    }
}
