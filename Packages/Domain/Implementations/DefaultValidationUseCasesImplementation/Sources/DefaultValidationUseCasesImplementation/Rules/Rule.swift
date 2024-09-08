protocol Rule {
    typealias ValidationFailureMessage = String

    func validate(_ string: String) -> ValidationFailureMessage?
}
