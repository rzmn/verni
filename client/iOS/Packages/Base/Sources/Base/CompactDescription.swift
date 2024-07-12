public protocol CompactDescription: CustomStringConvertible {
    var compactDescription: String { get }
}

public extension CompactDescription {
    var description: String {
        compactDescription
    }

    var compactDescription: String {
        let mirror = Mirror(reflecting: self)
        let properties = mirror.children.compactMap { (property, value) -> String? in
            guard let property = property else {
                return nil
            }
            if property.lowercased().contains("token"), let value = value as? CustomStringConvertible {
                return "\(property.prefix(3))=\(value.description.prefix(3))"
            } else {
                return "\(property.prefix(3))=\(value)"
            }
        }
        return "<\(properties)>"
    }
}
