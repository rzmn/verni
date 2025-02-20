import Testing
import CredentialsFormatValidationUseCase
@testable import DefaultValidationUseCasesImplementation

@Suite("LocalValidationUseCases Tests")
struct LocalValidationUseCasesTests {
    
    @Test("Valid email validation")
    func validEmailValidation() async throws {
        // Given
        let validator = LocalValidationUseCases()
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+label@domain.com",
            "123@numbers.com"
        ]
        
        // When/Then
        for email in validEmails {
            try validator.validateEmail(email)
        }
    }
    
    @Test("Invalid email validation")
    func invalidEmailValidation() async throws {
        // Given
        let validator = LocalValidationUseCases()
        let invalidEmails = [
            "",
            "notanemail",
            "@nodomain.com",
            "no@domain",
            "spaces in@email.com",
            "missing.domain@",
            ".starts.with.dot@domain.com"
        ]
        
        // When/Then
        for email in invalidEmails {
            do {
                try validator.validateEmail(email)
                Issue.record("Expected validation to fail for invalid email: \(email)")
            } catch EmailValidationError.isNotEmail {
                // Expected error
                continue
            }
        }
    }
    
    @Test("Strong password validation")
    func strongPasswordValidation() async {
        // Given
        let validator = LocalValidationUseCases()
        let strongPasswords = [
            "Password123",
            "StrongP@ss",
            "1234abcdEF",
            "Aa1!bcdefgh"
        ]
        
        // When/Then
        for password in strongPasswords {
            let result = validator.validatePassword(password)
            #expect(result == .strong)
        }
    }
    
    @Test("Weak password validation")
    func weakPasswordValidation() async {
        // Given
        let validator = LocalValidationUseCases()
        let weakPasswords = [
            "password",      // only lowercase
            "12345678",     // only numbers
            "UPPERCASE",    // only uppercase
            "!@#$%^&*",    // only special chars
        ]
        
        // When/Then
        for password in weakPasswords {
            let result = validator.validatePassword(password)
            if case .weak = result {
                #expect(true)
            } else {
                Issue.record("Expected weak password verdict for: \(password), got: \(result)")
            }
        }
    }
    
    @Test("Invalid password - too short")
    func invalidPasswordTooShort() async {
        // Given
        let validator = LocalValidationUseCases()
        let shortPasswords = [
            "",
            "a",
            "1234567"  // 7 chars, minimum is 8
        ]
        
        // When/Then
        for password in shortPasswords {
            let result = validator.validatePassword(password)
            if case .invalid(.minimalCharacterCount(8)) = result {
                #expect(true)
            } else {
                Issue.record("Expected invalid password (too short) verdict for: \(password), got: \(result)")
            }
        }
    }
    
    @Test("Invalid password - invalid characters")
    func invalidPasswordCharacters() async {
        // Given
        let validator = LocalValidationUseCases()
        let invalidPasswords = [
            "password£", // £ is not in allowed special chars
            "hello世界", // non-ASCII characters
            "tab\tchar" // control character
        ]
        
        // When/Then
        for password in invalidPasswords {
            let result = validator.validatePassword(password)
            if case .invalid(.hasInvalidCharacter) = result {
                #expect(true)
            } else {
                Issue.record("Expected invalid password (invalid chars) verdict for: \(password), got: \(result)")
            }
        }
    }
}
