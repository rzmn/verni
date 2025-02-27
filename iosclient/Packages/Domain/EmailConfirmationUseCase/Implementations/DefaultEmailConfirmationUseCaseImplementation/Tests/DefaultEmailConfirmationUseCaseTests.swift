import Testing
import Logging
import Foundation
import Entities
import Api
import Convenience
import TestInfrastructure
import EmailConfirmationUseCase
import MockApiImplementation
@testable import DefaultEmailConfirmationUseCaseImplementation

@Suite("DefaultEmailConfirmationUseCase Tests")
struct DefaultEmailConfirmationUseCaseTests {
    @Test("Send confirmation code successfully")
    func sendConfirmationCodeSuccess() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        
        let useCase = DefaultEmailConfirmationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        // When
        try await useCase.sendConfirmationCode()
        
        // Then
        #expect(api.sendCodeCallCount == 1)
    }
    
    @Test("Send confirmation code failure")
    func sendConfirmationCodeFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        api.shouldFailRequest = true
        
        let useCase = DefaultEmailConfirmationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        // When/Then
        do {
            try await useCase.sendConfirmationCode()
            throw InternalError.error("Should have failed")
        } catch is SendEmailConfirmationCodeError {
            // Expected error
        }
        #expect(api.sendCodeCallCount == 1)
    }
    
    @Test("Confirm email successfully")
    func confirmEmailSuccess() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        
        let useCase = DefaultEmailConfirmationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        let code = "123456"
        
        // When
        try await useCase.confirm(code: code)
        
        // Then
        #expect(api.confirmEmailCallCount == 1)
        #expect(api.lastConfirmationCode == code)
    }
    
    @Test("Confirm email failure")
    func confirmEmailFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        api.shouldFailRequest = true
        
        let useCase = DefaultEmailConfirmationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        // When/Then
        do {
            try await useCase.confirm(code: "123456")
            throw InternalError.error("Should have failed")
        } catch is EmailConfirmationError {
            // Expected error
        }
        #expect(api.confirmEmailCallCount == 1)
    }
    
    @Test("Confirmation code length")
    func confirmationCodeLength() async {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        
        let useCase = DefaultEmailConfirmationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        // Then
        #expect(await useCase.confirmationCodeLength == 6)
    }
}
