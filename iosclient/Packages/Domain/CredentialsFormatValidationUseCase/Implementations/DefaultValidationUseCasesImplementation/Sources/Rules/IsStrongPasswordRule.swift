import CredentialsFormatValidationUseCase

struct IsStrongPasswordRule: Rule {
    let characterTypes: [PasswordValidationVerdict.CharacterType]
    let characterTypesCountToBeStrong: Int

    func validate(_ string: String) -> PasswordValidationVerdict.WeaknessReason? {
        let has = characterTypes.filter { type in
            string.contains(where: type.contains)
        }
        if has.count < characterTypesCountToBeStrong {
            return .shouldBeAtLeastNCharacterTypesCount(
                count: characterTypesCountToBeStrong,
                has: has,
                allowed: characterTypes
            )
        }
        return nil
    }
}
