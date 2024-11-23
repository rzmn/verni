public func modify<T>(_ object: T, block: (inout T) -> Void) -> T {
    var object = object
    block(&object)
    return object
}
