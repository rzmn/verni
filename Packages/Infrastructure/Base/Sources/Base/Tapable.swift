public func tap<T: AnyObject>(_ object: T, block: (T) -> Void) -> T {
    block(object)
    return object
}
