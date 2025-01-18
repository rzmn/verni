import Foundation
internal import SQLite

struct CodableBlob<T: Codable>: Value {
    typealias Datatype = Blob

    let datatypeValue: Blob

    static var declaredDatatype: String {
        Blob.declaredDatatype
    }

    let value: T

    init(value: T, encoder: JSONEncoder = JSONEncoder()) throws {
        self.value = value
        let data = try encoder.encode(value)
        datatypeValue = Blob(bytes: [UInt8](data))
    }

    static func fromDatatypeValue(_ datatypeValue: Blob) throws -> CodableBlob<T> {
        let data = Data(bytes: datatypeValue.bytes, count: datatypeValue.bytes.count)
        return try CodableBlob(value: try JSONDecoder().decode(T.self, from: data))
    }
}
