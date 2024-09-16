import Foundation

precedencegroup CompositionPrecedence {
    associativity: right
    higherThan: BitwiseShiftPrecedence
}
infix operator • : CompositionPrecedence

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

public func nop<A>(arg: A) {
}

public func nop<A>(arg: inout A) {
}

public func • <A, B>(f: @escaping (A) -> B, g: @escaping () -> A) -> () -> B {
    return { f(g()) }
}

public func • <A, B, C>(f: @escaping (B) -> C, g: @escaping (A) -> B) -> (A) -> C {
    return { a in f(g(a)) }
}

public func • <A, B, C>(f: @escaping (B) throws -> C, g: @escaping (A) throws -> B) -> (A) throws -> C {
    return { a in try f(g(a)) }
}

public func curry<A, B>(_ f: @escaping (A) -> B) -> (A) -> () -> B {
    return { a in { f(a) } }
}

public func curry<A, B>(_ f: @escaping (A) throws -> B) -> (A) -> () throws -> B {
    return { a in { try f(a) } }
}

public func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

public func curryFirst<A, B, C>(_ f: @escaping (A, B) -> C) -> (B) -> (A) -> C {
    return { b in { a in f(a, b) }}
}

public func curry<A, B, C>(_ f: @escaping (A, B) throws -> C) -> (A) -> (B) throws -> C {
    return { a in { b in try f(a, b) } }
}

public func curryFirst<A, B, C>(_ f: @escaping (A, B) throws -> C) -> (B) -> (A) throws -> C {
    return { b in { a in try f(a, b) }}
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A, B) -> (C) -> D {
    return { a, b in { c in f(a, b, c) } }
}
