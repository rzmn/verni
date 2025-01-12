import Domain

protocol TimeOrderedOperation {
    var id: String { get }
    var timestamp: MsSince1970 { get }
    
    func earlier(than operation: any TimeOrderedOperation) -> Bool
    func earlier(than operation: Self) -> Bool
}

extension TimeOrderedOperation {
    func earlier(than operation: Self) -> Bool {
        earlier(than: operation as (any TimeOrderedOperation))
    }
    
    func earlier(than operation: any TimeOrderedOperation) -> Bool {
        if timestamp != operation.timestamp {
            return timestamp < operation.timestamp
        }
        return id < operation.id
    }
}

extension Sequence where Element: TimeOrderedOperation {
    func ordered() -> [Element] {
        sorted { lhs, rhs in
            lhs.earlier(than: rhs)
        }
    }
}
