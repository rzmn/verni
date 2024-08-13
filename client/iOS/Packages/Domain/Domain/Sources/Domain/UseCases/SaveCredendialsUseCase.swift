public protocol SaveCredendialsUseCase {
    func save(email: String, password: String) async
}
