public protocol SaveCredendialsUseCase: Sendable {
    func save(email: String, password: String) async
}
