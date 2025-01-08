import Testing
@testable import DefaultLogoutUseCaseImplementation

@Suite struct LoggedOutHandlerTests {

    @Test func testAllowLogoutOnce() async {

        // given

        let handler = LoggedOutHandler()

        // when

        let allow = await handler.allowLogout()
        let dontAllow = await handler.allowLogout()

        // then

        #expect(allow == true)
        #expect(dontAllow == false)
    }
}
