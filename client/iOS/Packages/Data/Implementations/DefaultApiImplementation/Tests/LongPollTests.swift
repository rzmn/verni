import Testing
import Foundation
import ApiService
import Base
@testable import Api
@testable import DefaultApiImplementation

struct MockLongPollQueryUpdate: Sendable, Decodable, Equatable {
    let data: String
}

struct MockLongPollQuery<Update: Sendable>: LongPollQuery {

    func updateIsRelevant(_ update: Update) -> Bool {
        relevant
    }

    let relevant: Bool
    let eventId: String
    let method: String
}

struct MockApiServiceForLongPoll<Query: LongPollQuery>: ApiService where Query.Update: Decodable {
    let result: Result<LongPollResultDto<Query.Update>, ApiServiceError>

    init(type: Query.Type, result: Result<LongPollResultDto<Query.Update>, ApiServiceError>) {
        self.result = result
    }

    func run<Request, Response>(
        request: Request
    ) async throws(ApiServiceError) -> Response
    where Request: ApiServiceRequest, Response: Decodable, Response: Sendable {
        try result.map {
            print("[debug] \(type(of: $0)) \(Response.self)")
            if Response.self == VoidApiResponseDto.self {
                return VoidApiResponseDto.success as! Response
            } else {
                return $0 as! Response
            }
        }.get()
    }
}

@Suite struct LongPollTests {

    @Test func testLongPollSucceeded() async throws {

        // given

        let updates = [
            MockLongPollQueryUpdate(data: "data")
        ]
        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.success(updates))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let result = try await api.longPoll(
            query: query
        )

        // then

        #expect(result == updates)
    }

    @Test func testLongPollNoConnection() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.failure(.noConnection(InternalError.error("", underlying: nil))))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .noConnection = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollNoConnectionFromApiService() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.noConnection(InternalError.error("", underlying: nil)))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .noConnection = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollNoUpdates() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.failure(.noUpdates))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .noUpdates = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollInternalError() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.failure(.internalError(InternalError.error("", underlying: nil))))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .internalError = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollInternalErrorFromApiService() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.internalError(InternalError.error("", underlying: nil)))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .internalError = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollUnauthorized() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.unauthorized)
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .internalError = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollDecodingFailed() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.decodingFailed(InternalError.error("", underlying: nil)))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )

        // when

        let longPollError: LongPollError
        do {
            let _ = try await api.longPoll(
                query: query
            )
            Issue.record()
            return
        } catch {
            longPollError = error
        }

        // then

        guard case .internalError = longPollError else {
            Issue.record()
            return
        }
    }

    @Test func testLongPollReusePublisherForSameEventId() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.decodingFailed(InternalError.error("", underlying: nil)))
            )
        )
        let queryA = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )
        let queryB = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )
        let longPoll = DefaultLongPoll(api: api)

        // when

        let updateNotifierA = await longPoll.updateNotifier(for: queryA)
        let updateNotifierB = await longPoll.updateNotifier(for: queryB)

        // then

        #expect(updateNotifierA === updateNotifierB)
    }

    @Test func testLongPollDifferentPublishersForDifferentEventIds() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .failure(.decodingFailed(InternalError.error("", underlying: nil)))
            )
        )
        let queryA = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventIdA",
            method: "method"
        )
        let queryB = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventIdB",
            method: "method"
        )
        let longPoll = DefaultLongPoll(api: api)

        // when

        let updateNotifierA = await longPoll.updateNotifier(for: queryA)
        let updateNotifierB = await longPoll.updateNotifier(for: queryB)

        // then

        #expect(updateNotifierA !== updateNotifierB)
    }

    @Test func singlePollTest() async throws {

        // given

        let updates = [
            MockLongPollQueryUpdate(data: "data")
        ]
        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.success(updates))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )
        let poller = await Poller(query: query, api: api)

        // when

        let updatesFromPoll = try await poller.poll().get()

        // then

        #expect(updatesFromPoll == updates)
    }

    @Test func singlePollIrrelevantUpdateTest() async throws {

        // given

        let updates = [
            MockLongPollQueryUpdate(data: "data")
        ]
        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.success(updates))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: false,
            eventId: "eventId",
            method: "method"
        )
        let poller = await Poller(query: query, api: api)

        // when

        let updatesFromPoll = try await poller.poll().get()

        // then

        #expect(updatesFromPoll == [])
    }

    @Test func singlePollOfflineTest() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.failure(.noConnection(InternalError.error("", underlying: nil))))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )
        let poller = await Poller(query: query, api: api)

        // when

        let result = await poller.poll()

        // then

        guard case .failure(let error) = result, case .offline = error else {
            Issue.record()
            return
        }
    }

    @Test func singlePollInternalErrorTest() async throws {

        // given

        let api = DefaultApi(
            service: MockApiServiceForLongPoll(
                type: MockLongPollQuery<MockLongPollQueryUpdate>.self,
                result: .success(.failure(.internalError(InternalError.error("", underlying: nil))))
            )
        )
        let query = MockLongPollQuery<MockLongPollQueryUpdate>(
            relevant: true,
            eventId: "eventId",
            method: "method"
        )
        let poller = await Poller(query: query, api: api)

        // when

        let result = await poller.poll()

        // then

        guard case .failure(let error) = result, case .canceled = error else {
            Issue.record()
            return
        }
    }
}
