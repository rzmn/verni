extension Optional where Wrapped: Collection & ExpressibleByArrayLiteral {
    public var emptyIfNil: Wrapped {
        guard let self else {
            return Wrapped()
        }
        return self
    }
}
