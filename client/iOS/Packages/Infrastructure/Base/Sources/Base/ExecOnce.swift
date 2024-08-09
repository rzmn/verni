public enum ExecOnce {
    private class Holder<T> {
        var value: T?
        init(_ value: T) {
            self.value = value
        }
    }

    public static func block(_ block: @escaping () -> Void) -> () -> Void {
        let holder = Holder(block)
        return {
            guard let block = holder.value else {
                return
            }
            holder.value = nil
            block()
        }
    }

    public static func block<T>(_ block: @escaping (T) -> Void) -> (T) -> Void {
        let holder = Holder(block)
        return { arg in
            guard let block = holder.value else {
                return
            }
            holder.value = nil
            block(arg)
        }
    }
}
