public enum RemoteUpdate: Sendable {
    case newOperationsAvailable([Components.Schemas.SomeOperation])
}
