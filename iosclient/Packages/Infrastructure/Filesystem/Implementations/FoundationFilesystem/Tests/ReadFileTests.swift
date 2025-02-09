import Testing
import Foundation
import Filesystem
import TestLogging
@testable import FoundationFilesystem

@Suite struct ReadFileTests {

    @Test
    func ok() {

        // given

        let sample = createSampleDirectoryWithContent()

        // when

        var data: Data
        do {
            data = try sample.manager.readFile(at: sample.file)
        } catch {
            Issue.record("\(error)")
            return
        }

        // then

        #expect(sample.fileData = data)
    }

    @Test
    func failWhenDoesNotExists() {

        // given

        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)

        // when

        do {
            let _ = try manager.readFile(at: url)
            Issue.record()
        } catch {
            guard case .noSuchFile = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    @Test
    func failWhenIsFileAtPath() {

        // given

        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        let directoryUrl = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! manager.createDirectory(at: directoryUrl)

        // when

        do {
            let _ = try manager.readFile(at: directoryUrl)
            Issue.record()
        } catch {
            guard case .urlIsReferringToDirectory = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    @Test
    func failInternalError() {

        // given

        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        let fileUrl = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! Foundation.FileManager.default.createFile(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0])

        // when

        do {
            let data = try manager.readFile(at: fileUrl)
            print("\(data)")
            Issue.record()
        } catch {
            guard case .internal = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    private struct SampleDirectoryWithContent {
        let manager: FoundationFileManager
        let directory: URL
        let file: URL
        let fileData: Data
        let subdirectory: URL
    }

    private func createSampleDirectoryWithContent(
    ) -> SampleDirectoryWithContent {
        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        try! manager.createDirectory(at: directory)
        let data = "bla bla".data(using: .utf8)
        let file = directory.appending(component: UUID().uuidString)
        let subdirectory = directory.appending(component: UUID().uuidString)
        try! manager.createFile(at: file, content: data)
        try! manager.createDirectory(at: subdirectory)
        return SampleDirectoryWithContent(
            manager: manager,
            directory: directory,
            file: file,
            fileData: data,
            subdirectory: subdirectory
        )
    }
}
