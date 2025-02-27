import Testing
import Logging
import Foundation
import Entities
import Api
import Convenience
import TestInfrastructure
import PushRegistrationUseCase
import MockApiImplementation
import UserNotifications
import UIKit
@testable import DefaultPushRegistrationUseCaseImplementation

// TODO: inject notification center

@Suite("DefaultPushRegistrationUseCase Tests")
struct DefaultPushRegistrationUseCaseTests {
    
//    func setUp() {
//        // Reset mocks before each test
//        MockUserNotificationCenter.mockShared = nil
//        MockUIApplication.mockShared = nil
//    }
//    
//    @Test("Ask for push token - granted")
//    func askForPushTokenGranted() async throws {
//        // Given
//        let infrastructure = TestInfrastructureLayer()
//        let api = MockApi()
//        let notificationCenter = MockUserNotificationCenter.current() as! MockUserNotificationCenter
//        let application = MockUIApplication.shared as! MockUIApplication
//        notificationCenter.shouldGrantAuthorization = true
//        
//        let useCase = DefaultPushRegistrationUseCase(
//            api: api,
//            logger: infrastructure.logger
//        )
//        
//        // When
//        await useCase.askForPushToken()
//        try await infrastructure.testTaskFactory.runUntilIdle()
//        
//        // Then
//        #expect(notificationCenter.requestAuthorizationCallCount == 1)
//        #expect(application.registerForRemoteNotificationsCallCount == 1)
//    }
//    
//    @Test("Ask for push token - denied")
//    func askForPushTokenDenied() async throws {
//        // Given
//        let infrastructure = TestInfrastructureLayer()
//        let api = MockApi()
//        let notificationCenter = MockUserNotificationCenter.current() as! MockUserNotificationCenter
//        let application = MockUIApplication.shared as! MockUIApplication
//        notificationCenter.shouldGrantAuthorization = false
//        
//        let useCase = DefaultPushRegistrationUseCase(
//            api: api,
//            logger: infrastructure.logger
//        )
//        
//        // When
//        await useCase.askForPushToken()
//        try await infrastructure.testTaskFactory.runUntilIdle()
//        
//        // Then
//        #expect(notificationCenter.requestAuthorizationCallCount == 1)
//        #expect(application.registerForRemoteNotificationsCallCount == 0) // Should not register if denied
//    }
//    
//    @Test("Ask for push token - authorization failure")
//    func askForPushTokenAuthorizationFailure() async throws {
//        // Given
//        let infrastructure = TestInfrastructureLayer()
//        let api = MockApi()
//        let notificationCenter = MockUserNotificationCenter.current() as! MockUserNotificationCenter
//        let application = MockUIApplication.shared as! MockUIApplication
//        notificationCenter.shouldFailAuthorization = true
//        
//        let useCase = DefaultPushRegistrationUseCase(
//            api: api,
//            logger: infrastructure.logger
//        )
//        
//        // When
//        await useCase.askForPushToken()
//        try await infrastructure.testTaskFactory.runUntilIdle()
//        
//        // Then
//        #expect(notificationCenter.requestAuthorizationCallCount == 1)
//        #expect(application.registerForRemoteNotificationsCallCount == 0) // Should not register on failure
//    }
    
    @Test("Register push token successfully")
    func registerPushTokenSuccess() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        
        let useCase = DefaultPushRegistrationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        let tokenData = Data([0x01, 0x02, 0x03])
        
        // When
        await useCase.registerForPush(token: tokenData)
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(api.registerForPushNotificationsCallCount == 1)
        #expect(api.lastPushToken == "010203") // Verify token is formatted correctly
    }
    
    @Test("Register push token failure")
    func registerPushTokenFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockApi()
        api.shouldFailRequest = true
        
        let useCase = DefaultPushRegistrationUseCase(
            api: api,
            logger: infrastructure.logger
        )
        
        let tokenData = Data([0x01, 0x02, 0x03])
        
        // When
        await useCase.registerForPush(token: tokenData)
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(api.registerForPushNotificationsCallCount == 1)
    }
}

