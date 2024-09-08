public extension Result {
    var success: Success? {
        guard case .success(let success) = self else {
            return nil
        }
        return success
    }

    var failure: Failure? {
        guard case .failure(let failure) = self else {
            return nil
        }
        return failure
    }
}
