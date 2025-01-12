public enum CreateDirectoryError: Error, Sendable {
    case urlIsReferringToFile
    case `internal`(Error)
}
