public protocol ApiErrorConvertible: Sendable {
    var apiError: Components.Schemas._Error { get }
}

extension Operations.Signup.Output.Conflict: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.Signup.Output.UnprocessableContent: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.Signup.Output.InternalServerError: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.Login.Output.Conflict: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.Login.Output.InternalServerError: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.SearchUsers.Output.Unauthorized: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.SearchUsers.Output.InternalServerError: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}

extension Operations.GetAvatars.Output.InternalServerError: ApiErrorConvertible {
    public var apiError: Components.Schemas._Error {
        switch body {
        case .json(let payload):
            return payload.error
        }
    }
}
