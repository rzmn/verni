public enum CreateFileError: Error, Sendable {
    case urlIsReferringToDirectory
    case alreadyExists
    case `internal`(Error)
}
