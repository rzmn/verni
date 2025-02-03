import OpenAPIRuntime

public enum ApiError: Error {
    case expected(Components.Schemas._Error)
    case undocumented(statusCode: Int, OpenAPIRuntime.UndocumentedPayload)
}

public protocol ApiResult: Sendable {
    associatedtype Output: Sendable
    
    @discardableResult
    func get() throws(ApiError) -> Output
}

extension Operations.Signup.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.StartupData {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .conflict(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .unprocessableContent(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.Login.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.StartupData {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .conflict(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.SearchUsers.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> [Components.Schemas.SomeOperation] {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .unauthorized(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.GetAvatars.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> [String: Components.Schemas.Image] {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response.additionalProperties
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.UpdateEmail.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.Empty {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .conflict(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .unauthorized(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .unprocessableContent(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.UpdatePassword.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.Empty {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .conflict(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .unauthorized(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .unprocessableContent(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.RegisterForPushNotifications.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.Empty {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .unauthorized(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.SendEmailConfirmationCode.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.Empty {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .unauthorized(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}

extension Operations.ConfirmEmail.Output: ApiResult {
    @discardableResult
    public func get() throws(ApiError) -> Components.Schemas.Empty {
        switch self {
        case .ok(let value):
            switch value.body {
            case .json(let body):
                return body.response
            }
        case .conflict(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .internalServerError(let value):
            switch value.body {
            case .json(let body):
                throw .expected(body.error)
            }
        case .undocumented(let statusCode, let payload):
            throw .undocumented(statusCode: statusCode, payload)
        }
    }
}
