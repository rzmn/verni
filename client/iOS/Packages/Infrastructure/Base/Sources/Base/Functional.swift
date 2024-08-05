import Foundation

public func weak<O: AnyObject, A>(_ object: O, _ method: @escaping (O) -> (A) -> Void) -> (A) -> Void {
    return { [weak object] args in
        if let object = object {
            method(object)(args)
        }
    }
}

public func weak<O: AnyObject>(_ object: O, _ method: @escaping (O) -> () -> Void) -> () -> Void {
    return { [weak object] in
        if let object = object {
            method(object)()
        }
    }
}

public func weak<O: AnyObject, A, B>(_ object: O, _ method: @escaping (O) -> (A, B) -> Void) -> (A, B) -> Void {
    return { [weak object] a, b in
        if let object = object {
            method(object)(a, b)
        }
    }
}

public func weak<O: AnyObject, A, B>(_ object: O, _ method: @escaping (O) -> (A) -> B, fallback: @escaping @autoclosure () -> B) -> (A) -> B {
    return { [weak object] args in
        if let object = object {
            return method(object)(args)
        } else {
            return fallback()
        }
    }
}

public func weak<O: AnyObject, A>(_ object: O, _ method: @escaping (O) -> () -> A, fallback: @escaping @autoclosure () -> A) -> () -> A {
    return { [weak object] in
        if let object = object {
            return method(object)()
        } else {
            return fallback()
        }
    }
}

public func weak<O: AnyObject, A, B>(_ object: O, _ method: @escaping (O) -> (A) throws -> B, fallback: @escaping @autoclosure () -> B) -> (A) throws -> B {
    return { [weak object] args in
        if let object = object {
            return try method(object)(args)
        } else {
            return fallback()
        }
    }
}

