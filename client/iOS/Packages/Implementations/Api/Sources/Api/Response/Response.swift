protocol Response {
    static var overridenValue: Self? { get }
}

typealias DecodableResponse = (Decodable & Response)
