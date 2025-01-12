protocol Rule<Verdict> {
    associatedtype Verdict

    func validate(_ string: String) -> Verdict
}
