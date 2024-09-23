import Foundation

// swiftlint:disable identifier_name

precedencegroup CompositionPrecedence {
    associativity: right
    higherThan: BitwiseShiftPrecedence
}
infix operator • : CompositionPrecedence

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

public func curry<A, B, C>(_ f: @escaping (A, B) throws -> C) -> (A) -> (B) throws -> C {
    return { a in { b in try f(a, b) } }
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A, B) -> (C) -> D {
    return { a, b in { c in f(a, b, c) } }
}

// swiftlint:enable identifier_name
